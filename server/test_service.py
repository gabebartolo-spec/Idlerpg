"""Independent HTTP clients against a real listening service and temporary database."""
import concurrent.futures
from contextlib import closing
import socket
import sqlite3
import tempfile
import threading
import time
import unittest
from pathlib import Path

import httpx
import uvicorn

from server.app import SESSION_SECONDS, create_app, digest


class ServiceTest(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.database = Path(self.directory.name) / "test.sqlite3"
        self.stamp = 1800000000
        self.clients = []
        self.start()

    def start(self):
        self.socket = socket.socket()
        self.socket.bind(("127.0.0.1", 0))
        self.socket.listen(128)
        self.url = "http://127.0.0.1:" + str(self.socket.getsockname()[1])
        self.server = uvicorn.Server(uvicorn.Config(create_app(self.database, lambda: self.stamp), log_level="error", access_log=False))
        self.thread = threading.Thread(target=lambda: self.server.run(sockets=[self.socket]), daemon=True)
        self.thread.start()
        for _ in range(200):
            if self.server.started:
                return
            time.sleep(.01)
        self.fail("Service did not listen")

    def stop(self):
        self.server.should_exit = True
        self.thread.join(5)
        self.assertFalse(self.thread.is_alive(), "Service failed to stop")
        self.socket.close()

    def tearDown(self):
        for client in self.clients:
            client.close()
        self.stop()
        self.directory.cleanup()

    def account(self, name="Moss Walker"):
        client = httpx.Client(base_url=self.url, timeout=10)
        self.clients.append(client)
        response = client.post("/v1/accounts", json={"name": name})
        self.assertEqual(response.status_code, 200, response.text)
        credentials = response.json()
        client.headers["Authorization"] = "Bearer " + credentials["token"]
        return client, credentials

    def post(self, client, path, body=None, key=None):
        return client.post(path, json=body or {}, headers={"Idempotency-Key": key or __import__("secrets").token_hex(16)})

    def earn(self, client):
        outing = self.post(client, "/v1/outings").json()
        self.stamp += 300
        return self.post(client, "/v1/outings/" + outing["id"] + "/open")

    def test_private_profile_and_recovery_across_devices(self):
        a, credentials = self.account()
        b, _ = self.account("Second Walker")
        self.earn(a)
        self.assertEqual(b.get("/v1/profile").json()["gold"], 0)
        self.assertEqual(a.get("/v1/profile").json()["gold"], 20)
        self.assertEqual(b.get("/v1/profile/" + credentials["account_id"]).status_code, 404)
        self.assertEqual(self.post(a, "/v1/builds", {"build": "thornward", "gold": 999}).status_code, 422)
        recovered = b.post("/v1/recover", json={"account_id": credentials["account_id"], "recovery_key": credentials["recovery_key"]})
        self.assertEqual(recovered.status_code, 200)
        self.assertEqual(a.get("/v1/profile").status_code, 401)
        b.headers["Authorization"] = "Bearer " + recovered.json()["token"]
        self.assertEqual(b.get("/v1/profile").json()["gold"], 20)
        with closing(sqlite3.connect(self.database)) as db:
            self.assertEqual(db.execute("SELECT recovery_hash FROM accounts WHERE id=?", (credentials["account_id"],)).fetchone()[0], digest(credentials["recovery_key"]))
            data = " ".join(str(r) for r in db.execute("SELECT * FROM sessions"))
            self.assertNotIn(recovered.json()["token"], data)

    def test_expiry_logout_invalid_recovery_and_rate_limit(self):
        a, credentials = self.account()
        self.stamp += SESSION_SECONDS
        self.assertEqual(a.get("/v1/profile").status_code, 401)
        payload = {"account_id": credentials["account_id"], "recovery_key": "x" * 43}
        for _ in range(30):
            self.assertEqual(a.post("/v1/recover", json=payload).status_code, 401)
        self.assertEqual(a.post("/v1/recover", json=payload).status_code, 429)
        self.stamp += 3600
        payload["recovery_key"] = credentials["recovery_key"]
        response = a.post("/v1/recover", json=payload)
        a.headers["Authorization"] = "Bearer " + response.json()["token"]
        self.assertEqual(a.post("/v1/logout").status_code, 200)
        self.assertEqual(a.get("/v1/profile").status_code, 401)

    def test_server_clock_chest_ownership_and_replay(self):
        a, _ = self.account()
        b, _ = self.account("Other Walker")
        self.assertEqual(self.post(a, "/v1/outings", {"time": self.stamp + 99999}).status_code, 422)
        start = self.post(a, "/v1/outings", key="start-outing")
        self.assertEqual(start.status_code, 200)
        self.assertEqual(self.post(a, "/v1/outings", key="start-outing").json(), start.json())
        self.assertEqual(self.post(a, "/v1/outings").status_code, 409)
        path = "/v1/outings/" + start.json()["id"] + "/open"
        self.assertEqual(self.post(b, path).status_code, 404)
        self.assertEqual(self.post(a, path).status_code, 409)
        self.stamp -= 50
        self.assertEqual(self.post(a, path).status_code, 409)
        self.stamp += 350
        self.assertEqual(self.post(a, path, {"gold": 9999}).status_code, 422)
        self.assertEqual(self.post(a, path, key="open-outing").status_code, 200)
        self.assertEqual(self.post(a, path, key="open-outing").status_code, 200)
        self.assertEqual(self.post(a, path).status_code, 200)
        self.assertEqual(a.get("/v1/profile").json()["gold"], 20)
        self.assertEqual(self.post(a, "/v1/outings", key="open-outing").status_code, 409)
        with closing(sqlite3.connect(self.database)) as db:
            self.assertEqual(db.execute("SELECT sum(delta),count(*) FROM ledger").fetchone(), (20, 1))

    def test_two_devices_cannot_spend_same_balance(self):
        a, credentials = self.account()
        for _ in range(3):
            self.assertEqual(self.earn(a).status_code, 200)
        device = httpx.Client(base_url=self.url, headers={"Authorization": "Bearer " + credentials["token"]})
        self.clients.append(device)
        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            results = list(pool.map(lambda x: self.post(x[0], "/v1/builds", {"build": x[1]}).status_code, [(a, "thornward"), (device, "keeper")]))
        self.assertEqual(sorted(results), [200, 409])
        profile = a.get("/v1/profile").json()
        self.assertIn(profile["gold"], (0, 20))
        self.assertEqual(len(profile["builds"]), 2)
        owned = next(build for build in profile["builds"] if build != "trail")
        self.assertEqual(self.post(a, "/v1/builds", {"build": owned}).status_code, 200)
        with closing(sqlite3.connect(self.database)) as db:
            self.assertEqual(db.execute("SELECT sum(delta) FROM ledger").fetchone()[0], profile["gold"])

    def test_concurrent_chest_opening_settles_once(self):
        a, credentials = self.account()
        outing = self.post(a, "/v1/outings").json()
        self.stamp += 300
        def open_one(_):
            with httpx.Client(base_url=self.url, headers={"Authorization": "Bearer " + credentials["token"]}) as client:
                return self.post(client, "/v1/outings/" + outing["id"] + "/open").status_code
        with concurrent.futures.ThreadPoolExecutor(3) as pool:
            self.assertEqual(list(pool.map(open_one, range(3))), [200, 200, 200])
        self.assertEqual(a.get("/v1/profile").json()["gold"], 20)

    def test_three_independent_accounts_share_durable_roster(self):
        a, ca = self.account("Amber")
        b, cb = self.account("Birch")
        c, cc = self.account("Cedar")
        response = self.post(a, "/v1/guilds", {"name": "Lamplighters"})
        invite = response.json()["guild"]["invite"]
        for client in (b, c):
            self.assertEqual(self.post(client, "/v1/guild/join", {"invite": invite}).status_code, 200)
        expected = {ca["account_id"], cb["account_id"], cc["account_id"]}
        self.assertEqual({m["id"] for m in c.get("/v1/guild").json()["guild"]["members"]}, expected)
        self.earn(a)
        self.stop()
        self.start()
        for client in self.clients:
            client.base_url = self.url
        self.assertEqual(len(b.get("/v1/guild").json()["guild"]["members"]), 3)
        self.assertEqual(self.post(a, "/v1/guild/leave").status_code, 200)
        guild = b.get("/v1/guild").json()["guild"]
        self.assertIn(guild["leader"], (cb["account_id"], cc["account_id"]))
        self.assertEqual(a.get("/v1/profile").json()["gold"], 20)
        self.assertEqual(self.post(a, "/v1/guild/join", {"invite": invite}).status_code, 200)
        self.assertEqual(self.post(a, "/v1/guild/join", {"invite": invite}).status_code, 409)
        for client in (a, b, c):
            self.assertEqual(self.post(client, "/v1/guild/leave").status_code, 200)
        self.assertEqual(self.post(a, "/v1/guild/join", {"invite": invite}).status_code, 404)

    def test_concurrent_last_roster_slot_and_name_validation(self):
        a, _ = self.account()
        self.assertEqual(a.post("/v1/accounts", json={"name": "<script>"}).status_code, 422)
        invite = self.post(a, "/v1/guilds", {"name": "Lamplighters"}).json()["guild"]["invite"]
        for i in range(8):
            member, _ = self.account("Walker " + str(i))
            self.assertEqual(self.post(member, "/v1/guild/join", {"invite": invite}).status_code, 200)
        b, _ = self.account("Birch")
        c, _ = self.account("Cedar")
        with concurrent.futures.ThreadPoolExecutor(2) as pool:
            results = list(pool.map(lambda client: self.post(client, "/v1/guild/join", {"invite": invite}).status_code, (b, c)))
        self.assertEqual(sorted(results), [200, 409])
        self.assertEqual(len(a.get("/v1/guild").json()["guild"]["members"]), 10)

    def test_future_database_refused(self):
        future = Path(self.directory.name) / "future.sqlite3"
        with closing(sqlite3.connect(future)) as db:
            db.execute("PRAGMA user_version=999")
        with self.assertRaises(RuntimeError):
            create_app(future)

    def test_pending_outing_and_retry_survive_restart_and_long_absence(self):
        a, credentials = self.account()
        outing = self.post(a, "/v1/outings", key="saved-outing").json()
        self.stop()
        self.stamp += 30 * 86400
        self.start()
        a.base_url = self.url
        # Expired session needs explicit recovery; old token cannot settle.
        self.assertEqual(a.get("/v1/profile").status_code, 401)
        recovered = a.post("/v1/recover", json={"account_id": credentials["account_id"], "recovery_key": credentials["recovery_key"]})
        self.assertEqual(recovered.status_code, 200)
        a.headers["Authorization"] = "Bearer " + recovered.json()["token"]
        profile = a.get("/v1/profile").json()
        self.assertEqual(profile["outing"], outing)
        replay = self.post(a, "/v1/outings", key="saved-outing")
        self.assertEqual(replay.json(), outing)
        self.assertEqual(self.post(a, "/v1/outings/" + outing["id"] + "/open").json()["profile"]["gold"], 20)
        self.assertEqual(a.get("/v1/profile").json()["outing"], None)

    def test_failed_actions_count_toward_limit(self):
        a, credentials = self.account()
        with closing(sqlite3.connect(self.database)) as db:
            db.execute("INSERT INTO limits VALUES(?,?,?)", ("action:" + credentials["account_id"], self.stamp, 299))
            db.commit()
        self.assertEqual(self.post(a, "/v1/guild/join", {"invite": "0" * 12}).status_code, 404)
        self.assertEqual(self.post(a, "/v1/guild/join", {"invite": "0" * 12}).status_code, 429)


if __name__ == "__main__":
    unittest.main()
