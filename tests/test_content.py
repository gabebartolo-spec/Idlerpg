"""Engine-free regression checks for expanded content cross-references."""
import copy
import json
from pathlib import Path
import sys
import unittest

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
from validate_content import validate  # noqa: E402


class ContentTests(unittest.TestCase):
    def setUp(self):
        def load(name):
            return json.loads((ROOT / "data" / f"{name}.json").read_text(encoding="utf-8"))
        self.items = load("items")["items"]
        self.enemies = load("enemies")["enemies"]
        self.zones = load("zones")["zones"]
        self.names = load("names")
        self.wastes = next(z for z in self.zones if z["id"] == "lantern_wastes")

    def errors(self):
        return validate(self.items, self.enemies, self.zones, self.names)

    def test_shipping_content(self):
        self.assertEqual(self.errors(), [])

    def test_missing_boss_drop(self):
        self.wastes["boss_drop"] = "missing"
        self.assertTrue(any("boss drop" in p for p in self.errors()))

    def test_boss_relic_cannot_enter_pool(self):
        relic = next(i for i in self.items if i["id"] == "last_lantern")
        relic["zones"] = ["lantern_wastes"]
        self.assertTrue(any("boss spoils" in p for p in self.errors()))

    def test_invalid_gate(self):
        self.wastes["requires_boss"] = "reed_shambler"
        self.assertTrue(any("required boss" in p for p in self.errors()))
        self.wastes["requires_boss"] = "lantern_eater"
        self.assertTrue(any("own boss" in p for p in self.errors()))

    def test_invalid_fight_count(self):
        self.wastes["combats_per_toll"] = 3
        self.assertTrue(any("combats_per_toll" in p for p in self.errors()))

    def test_missing_art(self):
        self.wastes["art"] = "res://assets/zones/missing.jpg"
        self.assertTrue(any("missing artwork" in p for p in self.errors()))

    def test_empty_narrative_pool(self):
        self.wastes["travel_lines"] = []
        self.assertTrue(any("travel_lines" in p for p in self.errors()))

    def test_unknown_special(self):
        item = copy.deepcopy(self.items[-1])
        item["special"] = "typo_guard"
        self.items[-1] = item
        self.assertTrue(any("unknown special" in p for p in self.errors()))


if __name__ == "__main__":
    unittest.main()
