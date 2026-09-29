#!/usr/bin/env python3
"""VESPERBELL content validator.

Cross-references the JSON content files the same way content.gd does at load,
plus structural checks. Runs anywhere Python runs (no Godot needed).
Exit code 0 = clean, 1 = problems listed.
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data"
SLOTS = {"weapon", "armor", "charm"}
SPECIALS = {"echo_hold", "light_foot", "deep_luck", "tithe", "no_retreat", "death_writ", "echo_loud", "first_strike", "ember_guard"}
RARITIES = {0, 1, 2, 3}


def load(name):
    with open(DATA / name, encoding="utf-8") as f:
        return json.load(f)


def validate(items, enemies, zones, names):
    problems = []

    item_ids = [i["id"] for i in items]
    enemy_ids = [e["id"] for e in enemies]
    zone_ids = [z["id"] for z in zones]

    for list_, label in [(item_ids, "item"), (enemy_ids, "enemy"), (zone_ids, "zone")]:
        dupes = {x for x in list_ if list_.count(x) > 1}
        if dupes:
            problems.append(f"duplicate {label} ids: {sorted(dupes)}")
        if "" in list_:
            problems.append(f"empty {label} id")

    for it in items:
        iid = it["id"]
        if it["slot"] not in SLOTS:
            problems.append(f"item {iid}: bad slot {it['slot']}")
        if it["rarity"] not in RARITIES:
            problems.append(f"item {iid}: bad rarity {it['rarity']}")
        if it["value"] < 0 or it["shards"] < 0:
            problems.append(f"item {iid}: negative value/shards")
        for z in it["zones"]:
            if z not in zone_ids:
                problems.append(f"item {iid}: unknown zone {z}")
        sp = it.get("special")
        if sp is not None and sp not in SPECIALS:
            problems.append(f"item {iid}: unknown special {sp}")
        if (sp == "first_strike" or it.get("boss_only", False)) and it["zones"]:
            problems.append(f"item {iid}: boss spoils must not sit in zone pools")

    for e in enemies:
        eid = e["id"]
        if e["zone"] not in zone_ids:
            problems.append(f"enemy {eid}: unknown zone {e['zone']}")
        if e["threat"] <= 0 or e["xp"] < 0 or e["gold"] < 0:
            problems.append(f"enemy {eid}: bad numbers")

    for z in zones:
        zid = z["id"]
        if z["min_level"] < 1 or z["toll_seconds"] <= 0:
            problems.append(f"zone {zid}: bad min_level/toll_seconds")
        for eid in z["enemies"]:
            if eid not in enemy_ids:
                problems.append(f"zone {zid}: unknown enemy {eid}")
            elif enemies[enemy_ids.index(eid)]["zone"] != zid:
                problems.append(f"zone {zid}: enemy {eid} belongs to another zone")
        for flag in ("elite", "boss"):
            ref = z.get(flag, "")
            if ref and ref not in enemy_ids:
                problems.append(f"zone {zid}: unknown {flag} {ref}")
        if z.get("combats_per_toll", 1) not in (1, 2):
            problems.append(f"zone {zid}: combats_per_toll must be 1 or 2")
        if z.get("boss_danger_bonus", 4) < 0:
            problems.append(f"zone {zid}: negative boss danger")
        boss_drop = z.get("boss_drop", "")
        if z.get("boss"):
            if boss_drop not in item_ids:
                problems.append(f"zone {zid}: unknown or missing boss drop {boss_drop}")
            elif not items[item_ids.index(boss_drop)].get("boss_only", False):
                problems.append(f"zone {zid}: boss drop must be boss-only")
        elif boss_drop:
            problems.append(f"zone {zid}: boss drop without a boss")
        required = z.get("requires_boss", "")
        if required:
            if required not in enemy_ids or not enemies[enemy_ids.index(required)].get("boss", False):
                problems.append(f"zone {zid}: invalid required boss {required}")
            elif enemies[enemy_ids.index(required)]["zone"] == zid:
                problems.append(f"zone {zid}: cannot require its own boss")
        art = z.get("art", "")
        if not art.startswith("res://assets/zones/") or not (ROOT / art.removeprefix("res://")).is_file():
            problems.append(f"zone {zid}: missing artwork {art}")
        for field in ("travel_lines", "discovery_lines"):
            if field in z and (not isinstance(z[field], list) or not z[field] or any(not isinstance(line, str) or not line for line in z[field])):
                problems.append(f"zone {zid}: invalid {field}")
        weights = z["rarity_weights"]
        if sum(weights.values()) <= 0:
            problems.append(f"zone {zid}: rarity weights sum to zero")
        pool_bands = {it["rarity"] for it in items
                      if zid in it["zones"] and not it.get("boss_only", False) and it.get("special") != "first_strike"}
        for band in weights:
            if int(band) not in pool_bands:
                problems.append(f"zone {zid}: rarity band {band} has no items")
        if z["objective"]["xp"] < 0 or z["objective"]["gold"] < 0:
            problems.append(f"zone {zid}: bad objective rewards")

    if not names["first"] or not names["epithet"]:
        problems.append("names.json: empty name lists")

    return problems


def main():
    items = load("items.json")["items"]
    enemies = load("enemies.json")["enemies"]
    zones = load("zones.json")["zones"]
    problems = validate(items, enemies, zones, load("names.json"))
    if problems:
        print("CONTENT PROBLEMS:")
        for p in problems:
            print("  -", p)
        sys.exit(1)
    print(f"content clean: {len(items)} items, {len(enemies)} enemies, {len(zones)} zones")


if __name__ == "__main__":
    main()
