"""Small single-host service with durable, transactional account and guild state."""
import hashlib
import json
import os
import re
import secrets
import sqlite3
import time
from contextlib import contextmanager
from pathlib import Path

from fastapi import FastAPI, Header, HTTPException, Request
from pydantic import BaseModel, ConfigDict, Field
from server import raid_rules

RULES_VERSION = 1
SESSION_SECONDS = 7 * 86400
BUILD_COSTS = {"trail": 0, "thornward": 40, "keeper": 60}


class Input(BaseModel):
    model_config = ConfigDict(extra="forbid", str_strip_whitespace=True)


class Name(Input):
    name: str = Field(min_length=2, max_length=24, pattern=r"^[A-Za-z][A-Za-z0-9 _-]+$")


class Recovery(Input):
    account_id: str = Field(min_length=32, max_length=32, pattern=r"^[a-f0-9]+$")
    recovery_key: str = Field(min_length=40, max_length=100)


class Build(Input):
    build: str


class Join(Input):
    invite: str = Field(min_length=12, max_length=12, pattern=r"^[a-f0-9]+$")


class Enrollment(Input):
    role: str
    build: str


def digest(value):
    return hashlib.sha256(value.encode()).hexdigest()


def create_app(database=None, clock=time.time):
    path = Path(database or os.environ.get("IDLE_DATABASE", "server/data/playtest.sqlite3"))
    path.parent.mkdir(parents=True, exist_ok=True)
    app = FastAPI(title="Idle RPG playtest service", version="0.1.0")

    @contextmanager
    def transaction():
        db = sqlite3.connect(path, timeout=15)
        db.row_factory = sqlite3.Row
        db.execute("PRAGMA foreign_keys=ON")
        try:
            db.execute("BEGIN IMMEDIATE")
            yield db
            db.commit()
        except Exception:
            db.rollback()
            raise
        finally:
            db.close()

    with transaction() as db:
        version = db.execute("PRAGMA user_version").fetchone()[0]
        if version not in (0, 1, 2):
            raise RuntimeError("Unsupported database version; refusing to modify it")
        for sql in [
            "CREATE TABLE IF NOT EXISTS accounts(id TEXT PRIMARY KEY, name TEXT NOT NULL, recovery_hash TEXT NOT NULL, gold INTEGER NOT NULL CHECK(gold>=0), created INTEGER NOT NULL)",
            "CREATE TABLE IF NOT EXISTS sessions(hash TEXT PRIMARY KEY, account TEXT NOT NULL REFERENCES accounts(id), expires INTEGER NOT NULL)",
            "CREATE TABLE IF NOT EXISTS builds(account TEXT NOT NULL REFERENCES accounts(id), build TEXT NOT NULL, PRIMARY KEY(account,build))",
            "CREATE TABLE IF NOT EXISTS outings(id TEXT PRIMARY KEY, account TEXT NOT NULL REFERENCES accounts(id), ready INTEGER NOT NULL, opened INTEGER NOT NULL DEFAULT 0, version INTEGER NOT NULL, gold INTEGER NOT NULL)",
            "CREATE UNIQUE INDEX IF NOT EXISTS one_pending_outing ON outings(account) WHERE opened=0",
            "CREATE TABLE IF NOT EXISTS ledger(account TEXT NOT NULL REFERENCES accounts(id), event TEXT NOT NULL, delta INTEGER NOT NULL, created INTEGER NOT NULL, PRIMARY KEY(account,event))",
            "CREATE TABLE IF NOT EXISTS retries(account TEXT NOT NULL REFERENCES accounts(id), key TEXT NOT NULL, fingerprint TEXT NOT NULL, response TEXT NOT NULL, PRIMARY KEY(account,key))",
            "CREATE TABLE IF NOT EXISTS guilds(id TEXT PRIMARY KEY, name TEXT NOT NULL, invite TEXT NOT NULL UNIQUE, leader TEXT NOT NULL REFERENCES accounts(id))",
            "CREATE TABLE IF NOT EXISTS members(account TEXT PRIMARY KEY REFERENCES accounts(id), guild TEXT NOT NULL REFERENCES guilds(id), joined INTEGER NOT NULL)",
            "CREATE TABLE IF NOT EXISTS limits(bucket TEXT PRIMARY KEY, start INTEGER NOT NULL, count INTEGER NOT NULL)",
            "CREATE TABLE IF NOT EXISTS raids(id TEXT PRIMARY KEY, guild TEXT NOT NULL, leader TEXT NOT NULL, ready INTEGER NOT NULL, rules TEXT NOT NULL, result TEXT)",
            "CREATE UNIQUE INDEX IF NOT EXISTS one_open_raid ON raids(guild) WHERE result IS NULL",
            "CREATE TABLE IF NOT EXISTS enrollments(raid TEXT NOT NULL REFERENCES raids(id), account TEXT NOT NULL REFERENCES accounts(id), name TEXT NOT NULL, role TEXT NOT NULL, build TEXT NOT NULL, stats TEXT NOT NULL, PRIMARY KEY(raid,account), UNIQUE(raid,role))",
            "CREATE TABLE IF NOT EXISTS raid_rewards(raid TEXT NOT NULL REFERENCES raids(id), account TEXT NOT NULL REFERENCES accounts(id), gold INTEGER NOT NULL, look TEXT NOT NULL, opened INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(raid,account))",
            "CREATE TABLE IF NOT EXISTS looks(account TEXT NOT NULL REFERENCES accounts(id), look TEXT NOT NULL, source TEXT NOT NULL, PRIMARY KEY(account,look))",
        ]:
            db.execute(sql)
        db.execute("PRAGMA user_version=2")

    def now():
        return int(clock())

    def throttle(db, bucket, maximum):
        stamp = now()
        row = db.execute("SELECT * FROM limits WHERE bucket=?", (bucket,)).fetchone()
        count = row["count"] if row and stamp - row["start"] < 3600 else 0
        if count >= maximum:
            raise HTTPException(429, "Try again later")
        db.execute("INSERT OR REPLACE INTO limits VALUES(?,?,?)", (bucket, row["start"] if count else stamp, count + 1))

    def session(db, account):
        token = secrets.token_urlsafe(32)
        expires = now() + SESSION_SECONDS
        db.execute("INSERT INTO sessions VALUES(?,?,?)", (digest(token), account, expires))
        return {"account_id": account, "token": token, "expires": expires}

    def authenticate(db, authorization):
        if not authorization or not authorization.startswith("Bearer "):
            raise HTTPException(401, "Sign in again")
        row = db.execute("SELECT account FROM sessions WHERE hash=? AND expires>?", (digest(authorization[7:]), now())).fetchone()
        if not row:
            raise HTTPException(401, "Sign in again")
        return row["account"]

    def profile(db, account):
        row = db.execute("SELECT id,name,gold FROM accounts WHERE id=?", (account,)).fetchone()
        outing = db.execute("SELECT id,ready,version,gold FROM outings WHERE account=? AND opened=0", (account,)).fetchone()
        member = db.execute("SELECT guild FROM members WHERE account=?", (account,)).fetchone()
        return {**dict(row), "rules_version": RULES_VERSION, "server_time": now(), "builds": [r[0] for r in db.execute("SELECT build FROM builds WHERE account=? ORDER BY build", (account,))], "looks": [r[0] for r in db.execute("SELECT look FROM looks WHERE account=? ORDER BY look", (account,))], "raid_chests": [dict(r) for r in db.execute("SELECT raid,gold,look FROM raid_rewards WHERE account=? AND opened=0", (account,))], "outing": dict(outing) if outing else None, "guild_id": member[0] if member else None}

    async def mutate(request, authorization, key, operation):
        if not key or not re.fullmatch(r"[A-Za-z0-9_-]{8,80}", key):
            raise HTTPException(400, "Provide an 8–80 character Idempotency-Key")
        body = await request.body()
        fingerprint = digest(request.url.path + ":" + body.decode())
        # Count failed authenticated actions too (for example guessed invites).
        # This separate commit is intentionally outside the action rollback.
        with transaction() as db:
            account = authenticate(db, authorization)
            throttle(db, "action:" + account, 300)
        with transaction() as db:
            account = authenticate(db, authorization)
            existing = db.execute("SELECT * FROM retries WHERE account=? AND key=?", (account, key)).fetchone()
            if existing:
                if existing["fingerprint"] != fingerprint:
                    raise HTTPException(409, "Retry key belongs to a different action")
                return json.loads(existing["response"])
            result = operation(db, account)
            db.execute("INSERT INTO retries VALUES(?,?,?,?)", (account, key, fingerprint, json.dumps(result)))
            return result

    @app.get("/health")
    def health():
        return {"status": "ok", "rules_version": RULES_VERSION}

    @app.post("/v1/accounts")
    def register(body: Name, request: Request):
        with transaction() as db:
            throttle(db, "register:" + request.client.host, 20)
            account = secrets.token_hex(16)
            recovery = secrets.token_urlsafe(32)
            # High-entropy recovery keys, not user-chosen passwords. Only hashes stored.
            db.execute("INSERT INTO accounts VALUES(?,?,?,?,?)", (account, body.name, digest(recovery), 0, now()))
            db.execute("INSERT INTO builds VALUES(?,?)", (account, "trail"))
            return {**session(db, account), "recovery_key": recovery}

    @app.post("/v1/recover")
    def recover(body: Recovery, request: Request):
        # Failed attempts must persist too, so check credentials after committing limits.
        with transaction() as db:
            throttle(db, "recover:" + request.client.host, 30)
        with transaction() as db:
            row = db.execute("SELECT recovery_hash FROM accounts WHERE id=?", (body.account_id,)).fetchone()
            if not row or not secrets.compare_digest(row[0], digest(body.recovery_key)):
                raise HTTPException(401, "Recovery details did not match")
            db.execute("DELETE FROM sessions WHERE account=?", (body.account_id,))
            return session(db, body.account_id)

    @app.get("/v1/profile")
    def get_profile(authorization: str | None = Header(default=None)):
        with transaction() as db:
            return profile(db, authenticate(db, authorization))

    @app.post("/v1/logout")
    def logout(authorization: str | None = Header(default=None)):
        with transaction() as db:
            authenticate(db, authorization)
            db.execute("DELETE FROM sessions WHERE hash=?", (digest(authorization[7:]),))
        return {"signed_out": True}

    @app.post("/v1/outings")
    async def start(request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Outings accept no uploaded stats or time")
        def operation(db, account):
            if db.execute("SELECT 1 FROM outings WHERE account=? AND opened=0", (account,)).fetchone():
                raise HTTPException(409, "Open your current supply chest first")
            outing = {"id": secrets.token_hex(16), "ready": now() + 300, "version": RULES_VERSION, "gold": 20}
            db.execute("INSERT INTO outings(id,account,ready,version,gold) VALUES(?,?,?,?,?)", (outing["id"], account, outing["ready"], outing["version"], outing["gold"]))
            return outing
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/outings/{outing_id}/open")
    async def open_chest(outing_id: str, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Chest contents are server-owned")
        def operation(db, account):
            row = db.execute("SELECT * FROM outings WHERE id=? AND account=?", (outing_id, account)).fetchone()
            if not row:
                raise HTTPException(404, "Chest not found")
            if now() < row["ready"]:
                raise HTTPException(409, "Still on the trail")
            if not row["opened"]:
                db.execute("UPDATE outings SET opened=1 WHERE id=?", (outing_id,))
                db.execute("UPDATE accounts SET gold=gold+? WHERE id=?", (row["gold"], account))
                db.execute("INSERT INTO ledger VALUES(?,?,?,?)", (account, "outing:" + outing_id, row["gold"], now()))
            return {"chest_id": outing_id, "gold": row["gold"], "profile": profile(db, account)}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/builds")
    async def buy(body: Build, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        def operation(db, account):
            if body.build not in BUILD_COSTS:
                raise HTTPException(422, "Unknown build")
            if not db.execute("SELECT 1 FROM builds WHERE account=? AND build=?", (account, body.build)).fetchone():
                cost = BUILD_COSTS[body.build]
                if not db.execute("UPDATE accounts SET gold=gold-? WHERE id=? AND gold>=?", (cost, account, cost)).rowcount:
                    raise HTTPException(409, "Earn more supply gold")
                db.execute("INSERT INTO builds VALUES(?,?)", (account, body.build))
                db.execute("INSERT INTO ledger VALUES(?,?,?,?)", (account, "build:" + body.build, -cost, now()))
            return profile(db, account)
        return await mutate(request, authorization, idempotency_key, operation)

    @app.get("/v1/builds")
    def build_catalog(authorization: str | None = Header(default=None)):
        with transaction() as db:
            authenticate(db, authorization)
        return {"builds": raid_rules.BUILDS, "costs": BUILD_COSTS, "raid_rules_version": raid_rules.VERSION}

    def guild_view(db, account):
        row = db.execute("SELECT g.* FROM guilds g JOIN members m ON g.id=m.guild WHERE m.account=?", (account,)).fetchone()
        if not row:
            return None
        members = [dict(r) for r in db.execute("SELECT a.id,a.name FROM accounts a JOIN members m ON a.id=m.account WHERE m.guild=? ORDER BY m.joined,a.id", (row["id"],))]
        return {**dict(row), "members": members}

    @app.get("/v1/guild")
    def get_guild(authorization: str | None = Header(default=None)):
        with transaction() as db:
            return {"guild": guild_view(db, authenticate(db, authorization))}

    @app.post("/v1/guilds")
    async def create_guild(body: Name, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        def operation(db, account):
            if guild_view(db, account):
                raise HTTPException(409, "Leave your current guild first")
            guild = secrets.token_hex(16)
            db.execute("INSERT INTO guilds VALUES(?,?,?,?)", (guild, body.name, secrets.token_hex(6), account))
            db.execute("INSERT INTO members VALUES(?,?,?)", (account, guild, now()))
            return {"guild": guild_view(db, account)}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/guild/join")
    async def join(body: Join, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        def operation(db, account):
            if guild_view(db, account):
                raise HTTPException(409, "Leave your current guild first")
            row = db.execute("SELECT id FROM guilds WHERE invite=?", (body.invite,)).fetchone()
            if not row:
                raise HTTPException(404, "Invite not found")
            if db.execute("SELECT count(*) FROM members WHERE guild=?", (row[0],)).fetchone()[0] >= 10:
                raise HTTPException(409, "Guild is full")
            db.execute("INSERT INTO members VALUES(?,?,?)", (account, row[0], now()))
            return {"guild": guild_view(db, account)}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/guild/leave")
    async def leave(request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Leave your own guild only")
        def operation(db, account):
            guild = guild_view(db, account)
            if guild:
                db.execute("DELETE FROM members WHERE account=?", (account,))
                others = [m for m in guild["members"] if m["id"] != account]
                if not others:
                    db.execute("DELETE FROM guilds WHERE id=?", (guild["id"],))
                elif guild["leader"] == account:
                    db.execute("UPDATE guilds SET leader=? WHERE id=?", (others[0]["id"], guild["id"]))
            return {"guild": None}
        return await mutate(request, authorization, idempotency_key, operation)

    def raid_access(db, account, raid_id):
        row = db.execute("SELECT * FROM raids WHERE id=?", (raid_id,)).fetchone()
        if not row:
            raise HTTPException(404, "Raid not found")
        member = db.execute("SELECT 1 FROM members WHERE account=? AND guild=?", (account, row["guild"])).fetchone()
        enrolled = db.execute("SELECT 1 FROM enrollments WHERE account=? AND raid=?", (account, raid_id)).fetchone()
        if not member and not enrolled and row["leader"] != account:
            raise HTTPException(404, "Raid not found")
        return row

    def raid_view(db, row):
        roster = [{**dict(r), "stats": json.loads(r["stats"])} for r in db.execute("SELECT account,name,role,build,stats FROM enrollments WHERE raid=? ORDER BY role", (row["id"],))]
        return {"id": row["id"], "ready": row["ready"], "server_time": now(), "rules": json.loads(row["rules"]), "roster": roster, "result": json.loads(row["result"]) if row["result"] else None}

    @app.get("/v1/raids")
    def list_raids(authorization: str | None = Header(default=None)):
        with transaction() as db:
            account = authenticate(db, authorization)
            rows = db.execute("SELECT DISTINCT r.* FROM raids r LEFT JOIN enrollments e ON e.raid=r.id LEFT JOIN members m ON m.guild=r.guild WHERE e.account=? OR m.account=? OR r.leader=? ORDER BY r.ready DESC LIMIT 20", (account, account, account))
            return {"raids": [raid_view(db, row) for row in rows]}

    @app.get("/v1/raids/{raid_id}")
    def get_raid(raid_id: str, authorization: str | None = Header(default=None)):
        with transaction() as db:
            account = authenticate(db, authorization)
            return {"raid": raid_view(db, raid_access(db, account, raid_id))}

    @app.post("/v1/raids")
    async def create_raid(request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Raid timing and rules are server-owned")
        def operation(db, account):
            guild = guild_view(db, account)
            if not guild or guild["leader"] != account:
                raise HTTPException(403, "Your guild leader starts the raid")
            if db.execute("SELECT 1 FROM raids WHERE guild=? AND result IS NULL", (guild["id"],)).fetchone():
                raise HTTPException(409, "A raid is already preparing")
            raid = secrets.token_hex(16)
            db.execute("INSERT INTO raids VALUES(?,?,?,?,?,NULL)", (raid, guild["id"], account, now() + 86400, json.dumps(raid_rules.rules())))
            return {"raid": raid_view(db, raid_access(db, account, raid))}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/raids/{raid_id}/enroll")
    async def enroll(raid_id: str, body: Enrollment, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        def operation(db, account):
            row = raid_access(db, account, raid_id)
            if row["result"] or now() >= row["ready"]:
                raise HTTPException(409, "Raid roster is locked")
            if not db.execute("SELECT 1 FROM members WHERE account=? AND guild=?", (account, row["guild"])).fetchone():
                raise HTTPException(403, "Join this guild to prepare")
            if body.role not in raid_rules.ROLES or body.build not in raid_rules.BUILDS:
                raise HTTPException(422, "Unknown role or build")
            if not db.execute("SELECT 1 FROM builds WHERE account=? AND build=?", (account, body.build)).fetchone():
                raise HTTPException(403, "Earn this build first")
            if db.execute("SELECT 1 FROM enrollments e JOIN raids r ON e.raid=r.id WHERE e.account=? AND e.raid<>? AND r.result IS NULL", (account, raid_id)).fetchone():
                raise HTTPException(409, "Already committed to another raid")
            if db.execute("SELECT 1 FROM enrollments WHERE raid=? AND role=? AND account<>?", (raid_id, body.role, account)).fetchone():
                raise HTTPException(409, "That role is already prepared")
            name = db.execute("SELECT name FROM accounts WHERE id=?", (account,)).fetchone()[0]
            db.execute("INSERT OR REPLACE INTO enrollments VALUES(?,?,?,?,?,?)", (raid_id, account, name, body.role, body.build, json.dumps(raid_rules.BUILDS[body.build])))
            return {"raid": raid_view(db, row)}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/raids/{raid_id}/resolve")
    async def resolve_raid(raid_id: str, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Raid result is server-owned")
        def operation(db, account):
            row = raid_access(db, account, raid_id)
            if now() < row["ready"]:
                raise HTTPException(409, "Still preparing")
            if not row["result"]:
                raid = raid_view(db, row)
                if raid["rules"]["version"] != raid_rules.VERSION:
                    raise HTTPException(409, "Raid rules require a compatible resolver")
                result = raid_rules.resolve(raid["roster"], raid["rules"])
                db.execute("UPDATE raids SET result=? WHERE id=?", (json.dumps(result), raid_id))
                for participant in raid["roster"]:
                    db.execute("INSERT INTO raid_rewards VALUES(?,?,?,?,0)", (raid_id, participant["account"], raid["rules"]["gold"] if result["won"] else 15, raid["rules"]["look"] if result["won"] else ""))
            return {"raid": raid_view(db, raid_access(db, account, raid_id))}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/raids/{raid_id}/open")
    async def open_raid_chest(raid_id: str, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Raid chest contents are server-owned")
        def operation(db, account):
            row = db.execute("SELECT * FROM raid_rewards WHERE raid=? AND account=?", (raid_id, account)).fetchone()
            if not row:
                raise HTTPException(404, "Chest not found")
            if not row["opened"]:
                db.execute("UPDATE raid_rewards SET opened=1 WHERE raid=? AND account=?", (raid_id, account))
                db.execute("UPDATE accounts SET gold=gold+? WHERE id=?", (row["gold"], account))
                db.execute("INSERT INTO ledger VALUES(?,?,?,?)", (account, "raid:" + raid_id, row["gold"], now()))
                if row["look"]:
                    db.execute("INSERT OR IGNORE INTO looks VALUES(?,?,?)", (account, row["look"], "raid:" + raid_id))
            return {"gold": row["gold"], "look": row["look"], "profile": profile(db, account)}
        return await mutate(request, authorization, idempotency_key, operation)

    @app.post("/v1/raids/{raid_id}/withdraw")
    async def withdraw(raid_id: str, request: Request, authorization: str | None = Header(default=None), idempotency_key: str | None = Header(default=None)):
        if await request.body() not in (b"", b"{}"):
            raise HTTPException(422, "Withdraw your own preparation only")
        def operation(db, account):
            row = raid_access(db, account, raid_id)
            if row["result"] or now() >= row["ready"]:
                raise HTTPException(409, "Raid roster is locked")
            db.execute("DELETE FROM enrollments WHERE raid=? AND account=?", (raid_id, account))
            return {"raid": raid_view(db, row)}
        return await mutate(request, authorization, idempotency_key, operation)

    return app
