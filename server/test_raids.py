import concurrent.futures
import copy
import json
import sqlite3
import unittest
from contextlib import closing

import httpx

from server import raid_rules
from server.app import create_app
from server.test_service import HTTPHarness


class RaidServiceTest(HTTPHarness):
    # Reuse the real HTTP harness, without repeating its unrelated tests.
    def prepare(self):
        self.a, self.ca = self.account("Amber")
        self.b, self.cb = self.account("Birch")
        self.c, self.cc = self.account("Cedar")
        guild = self.post(self.a, "/v1/guilds", {"name": "Lamplighters"}).json()["guild"]
        for client in (self.b, self.c):
            self.assertEqual(self.post(client, "/v1/guild/join", {"invite": guild["invite"]}).status_code, 200)
        created = self.post(self.a, "/v1/raids")
        self.assertEqual(created.status_code, 200, created.text)
        self.raid = created.json()["raid"]["id"]
        self.path = "/v1/raids/" + self.raid
        for client, role in zip((self.a, self.b, self.c), raid_rules.ROLES):
            self.assertEqual(self.post(client, self.path + "/enroll", {"role": role, "build": "trail"}).status_code, 200)

    def test_raid_offline_members_and_settlement_survive_departure(self):
        self.prepare()
        self.assertEqual(self.post(self.a, self.path + "/resolve").status_code, 409)
        self.assertEqual(self.post(self.b, "/v1/guild/leave").status_code, 200)
        self.stop()
        self.start()
        for client in self.clients:
            client.base_url = self.url
        self.stamp += 86400
        result = self.post(self.a, self.path + "/resolve", key="settle-raid").json()["raid"]
        self.assertTrue(result["result"]["won"])
        self.assertEqual(len(result["roster"]), 3)
        for client in (self.a, self.b, self.c):
            self.assertEqual(client.get(self.path).json()["raid"]["result"], result["result"])
            opened = self.post(client, self.path + "/open")
            self.assertEqual(opened.status_code, 200)
            self.assertEqual(opened.json()["profile"]["gold"], 60)
            self.assertEqual(opened.json()["profile"]["looks"], ["warden_lantern"])
            self.assertEqual(self.post(client, self.path + "/open").json()["profile"]["gold"], 60)
        self.assertEqual(self.post(self.a, self.path + "/resolve", key="settle-raid").json()["raid"], result)
        self.assertEqual(self.post(self.a, self.path + "/enroll", {"role": "damage", "build": "trail"}).status_code, 409)
        self.assertEqual(self.post(self.c, self.path + "/withdraw").status_code, 409)
        with closing(sqlite3.connect(self.database)) as db:
            self.assertEqual(db.execute("SELECT count(*),sum(delta) FROM ledger WHERE event=?", ("raid:" + self.raid,)).fetchone(), (3, 180))

    def test_raid_permissions_forgery_and_cross_guild_lock(self):
        self.prepare()
        outsider, _ = self.account("Outsider")
        self.assertEqual(outsider.get(self.path).status_code, 404)
        self.assertEqual(self.post(outsider, self.path + "/resolve").status_code, 404)
        self.assertEqual(self.post(self.b, "/v1/raids").status_code, 403)
        self.assertEqual(self.post(self.a, "/v1/raids").status_code, 409)
        self.assertEqual(self.post(self.c, self.path + "/enroll", {"role": "preparation", "build": "keeper"}).status_code, 403)
        self.assertEqual(self.post(self.c, self.path + "/enroll", {"role": "preparation", "build": "trail", "attack": 999}).status_code, 422)
        self.assertEqual(self.post(self.a, self.path + "/resolve", {"won": True}).status_code, 422)
        self.post(self.c, "/v1/guild/leave")
        self.post(self.c, "/v1/guilds", {"name": "Other Guild"})
        other = self.post(self.c, "/v1/raids").json()["raid"]["id"]
        self.assertEqual(self.post(self.c, "/v1/raids/" + other + "/enroll", {"role": "preparation", "build": "trail"}).status_code, 409)
        self.assertEqual(self.post(self.c, self.path + "/withdraw").status_code, 200)
        self.assertEqual(self.post(self.c, "/v1/raids/" + other + "/enroll", {"role": "preparation", "build": "trail"}).status_code, 200)

    def test_raid_no_show_failure_keeps_progress_and_grants_once(self):
        self.prepare()
        self.post(self.c, self.path + "/withdraw")
        self.stamp += 86400
        result = self.post(self.a, self.path + "/resolve").json()["raid"]["result"]
        self.assertFalse(result["won"])
        self.assertEqual(result["reason"], "Lantern seals remain")
        self.assertEqual(self.post(self.c, self.path + "/open").status_code, 404)
        self.assertEqual(self.post(self.b, self.path + "/open").json()["profile"]["gold"], 15)
        self.assertEqual(self.post(self.b, self.path + "/open").json()["profile"]["looks"], [])
        self.assertEqual(self.post(self.a, "/v1/raids").status_code, 200)

    def test_raid_concurrent_resolution_and_chest_claim(self):
        self.prepare()
        self.stamp += 86400
        with concurrent.futures.ThreadPoolExecutor(3) as pool:
            results = list(pool.map(lambda client: self.post(client, self.path + "/resolve").json()["raid"]["result"], (self.a, self.b, self.c)))
        self.assertEqual(results[0], results[1])
        self.assertEqual(results[1], results[2])
        def claim(_):
            with httpx.Client(base_url=self.url, headers={"Authorization": "Bearer " + self.ca["token"]}) as device:
                return self.post(device, self.path + "/open").status_code
        with concurrent.futures.ThreadPoolExecutor(3) as pool:
            self.assertEqual(list(pool.map(claim, range(3))), [200, 200, 200])
        self.assertEqual(self.a.get("/v1/profile").json()["gold"], 60)
        with closing(sqlite3.connect(self.database)) as db:
            self.assertEqual(db.execute("SELECT count(*) FROM raid_rewards WHERE raid=?", (self.raid,)).fetchone()[0], 3)
            self.assertEqual(db.execute("SELECT count(*) FROM ledger WHERE event=?", ("raid:" + self.raid,)).fetchone()[0], 1)

    def test_raid_frozen_stats_and_incompatible_version(self):
        self.prepare()
        self.earn(self.b)
        self.earn(self.b)
        self.assertEqual(self.post(self.b, "/v1/builds", {"build": "thornward"}).status_code, 200)
        self.assertEqual(self.b.get(self.path).json()["raid"]["roster"][2]["build"], "trail")
        self.assertTrue(all(m["stats"]["hp"] == 45 for m in self.b.get(self.path).json()["raid"]["roster"]))
        with closing(sqlite3.connect(self.database)) as db:
            row = db.execute("SELECT rules FROM raids WHERE id=?", (self.raid,)).fetchone()
            incompatible = json.loads(row[0])
            incompatible["version"] = 999
            db.execute("UPDATE raids SET rules=? WHERE id=?", (json.dumps(incompatible), self.raid))
            db.commit()
        self.stamp += 86400
        self.assertEqual(self.post(self.a, self.path + "/resolve").status_code, 409)
        with closing(sqlite3.connect(self.database)) as db:
            self.assertEqual(db.execute("SELECT count(*) FROM raid_rewards").fetchone()[0], 0)

    def test_raid_late_join_and_occupied_role_rejected(self):
        self.prepare()
        self.assertEqual(self.post(self.c, self.path + "/enroll", {"role": "damage", "build": "trail"}).status_code, 409)
        self.post(self.c, self.path + "/withdraw")
        self.stamp += 86400
        self.assertEqual(self.post(self.c, self.path + "/enroll", {"role": "preparation", "build": "trail"}).status_code, 409)
        self.assertEqual(len(self.a.get(self.path).json()["raid"]["roster"]), 2)

    def test_additive_schema_upgrade_preserves_existing_accounts(self):
        a, credentials = self.account()
        self.earn(a)
        with closing(sqlite3.connect(self.database)) as db:
            for table in ("raid_rewards", "enrollments", "looks", "raids"):
                db.execute("DROP TABLE " + table)
            db.execute("PRAGMA user_version=1")
            db.commit()
        create_app(self.database, lambda: self.stamp)
        self.assertEqual(a.get("/v1/profile").json()["gold"], 20)
        self.assertEqual(a.get("/v1/profile").json()["id"], credentials["account_id"])


class RaidRulesTest(unittest.TestCase):
    def roster(self, damage="trail", protection="trail", preparation="trail"):
        return [{"account": role, "role": role, "stats": copy.deepcopy(raid_rules.BUILDS[build])} for role, build in zip(raid_rules.ROLES, (damage, protection, preparation))]

    def test_starter_victory_and_every_role_counterfactual(self):
        roster = self.roster()
        result = raid_rules.resolve(roster, raid_rules.rules())
        self.assertTrue(result["won"])
        self.assertGreater(result["contributions"]["protection"]["prevented"], 0)
        self.assertEqual(result["contributions"]["preparation"]["seals"], 3)
        self.assertGreater(result["contributions"]["preparation"]["healed"], 0)
        for role in raid_rules.ROLES:
            removed = raid_rules.resolve([m for m in roster if m["role"] != role], raid_rules.rules())
            self.assertFalse(removed["won"], role + " was a spectator")
        self.assertEqual(result, raid_rules.resolve(roster, raid_rules.rules()))

    def test_developing_preparation_matters_with_earned_damage(self):
        roster = self.roster(damage="keeper", protection="thornward")
        self.assertTrue(raid_rules.resolve(roster, raid_rules.rules())["won"])
        self.assertFalse(raid_rules.resolve(roster[:2], raid_rules.rules())["won"])

    def test_every_earned_build_can_cover_the_three_roles(self):
        for build in raid_rules.BUILDS:
            self.assertTrue(raid_rules.resolve(self.roster(build, build, build), raid_rules.rules())["won"], build)


if __name__ == "__main__":
    unittest.main()
