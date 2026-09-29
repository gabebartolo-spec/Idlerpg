#!/usr/bin/env python3
"""VESPERBELL balance simulator.

A Python mirror of the GDScript expedition rules (rng.gd, hero.gd, loot.gd,
expedition.gd) used to sanity-check death rates, pacing, and loot density
without a Godot binary. If you change constants in GDScript, mirror them here
and re-run.

Usage: python3 tools/balance_sim.py [runs_per_cell]
"""
import random
import sys

# ---------------------------------------------------------------- constants (mirror src/sim/*)
XP_THRESHOLDS = {1: 0, 2: 45, 3: 110, 4: 210, 5: 350, 6: 540, 7: 780, 8: 1100}
MAX_LEVEL = 8
ECHO_CAP = 5
DEATH_SAVE_BASE = 40
WRATH_BONUS = 3

BASE_DROP_PERCENT = 26
LUCK_DROP_PERCENT = 3
ELITE_BONUS_PERCENT = 15  # flat luck added for elites in expedition.gd
TOLL_SECONDS = 120

# Read content directly so new roads, enemies and rewards cannot silently drift.
import json
from pathlib import Path
DATA = Path(__file__).resolve().parent.parent / "data"
_ENEMIES = {e["id"]: e for e in json.loads((DATA / "enemies.json").read_text())["enemies"]}
_ZONE_DEFS = json.loads((DATA / "zones.json").read_text())["zones"]


def enemy_tuple(enemy_id):
    e = _ENEMIES[enemy_id]
    return e["name"], e["threat"], e["xp"], e["gold"]


ZONES = {
    z["id"]: dict(z, enemies=[enemy_tuple(e) for e in z["enemies"]],
                  boss=enemy_tuple(z["boss"]) if z["boss"] else None,
                  elite=enemy_tuple(z["elite"]) if z["elite"] else None)
    for z in _ZONE_DEFS
}
OBJ = {z["id"]: (z["objective"]["xp"], z["objective"]["gold"]) for z in _ZONE_DEFS}

# Gear bonus assumption by hero level (what a player typically wears):
# (might, ward, luck) on top of base stats.
def gear_for(level):
    if level <= 2:
        return (2, 2, 1)
    if level <= 4:
        return (4, 3, 1)
    return (5, 4, 2)


def base_stats(level):
    return {"might": 3 + level // 2, "ward": 3 + (level - 1) // 2,
            "luck": 1 + (1 if level >= 4 else 0) + (1 if level >= 7 else 0)}


def grit_max(ward):
    return 2 + ward // 5


def danger_at(zone, toll_index):
    return zone["danger_base"] + max(0, toll_index - 2)


def run_once(rng, zone_id, depth, level, luck_boost=0, belfry=(0, 0, 0), specials=frozenset()):
    """Statistical rules mirror, not seed-identical to Godot's narrative RNG stream.

    Assumes Wrath from L3 and Pilgrim from L6, plus typical level-appropriate gear.
    Explicit specials and Belfry bonuses can be used to compare late-game builds.
    Returns (status, xp, gold, loot_count, wounds).
    """
    zone = ZONES[zone_id]
    gear = gear_for(level)
    stats = {k: base_stats(level)[k] + gear[i] + belfry[i]
             for i, k in enumerate(("might", "ward", "luck"))}
    grit = grit_max(stats["ward"])
    echo = 0
    xp = gold = loot = wounds = combats = 0
    ward_spent = False
    fights = zone.get("combats_per_toll", 1)
    for i in range(depth):
        danger_base = danger_at(zone, i) + (1 if "light_foot" in specials else 0)
        is_final = i == depth - 1
        luck = stats["luck"] + luck_boost
        if "no_retreat" in specials:
            luck *= 2
        if "deep_luck" in specials:
            luck += i
        if level >= 6 and i >= 2:
            luck += 2
        for fight in range(fights):
            boss = bool(is_final and fight == fights - 1 and zone["boss"])
            elite = bool(not boss and zone["elite"] and i >= zone.get("elite_from_toll", 99) and rng.random() < 0.2)
            enemy = zone["boss"] if boss else (zone["elite"] if elite else rng.choice(zone["enemies"]))
            _, threat, exp_, gol = enemy
            danger = danger_base + (zone.get("boss_danger_bonus", 4) if boss else 0)
            combats += 1
            might = stats["might"] + echo * (2 if "echo_loud" in specials else 1)
            if level >= 3 and (combats - 1) % 3 == 2:
                might += WRATH_BONUS
            auto_win = "first_strike" in specials and fight == 0
            win_chance = max(15, min(95, 50 + (might - threat) * 8 - danger * 4))
            win = auto_win or rng.randrange(100) < win_chance
            wound_chance = max(5, min(85, 30 + danger * 12 - stats["ward"] * 2 - (5 if win else 0)))
            wounded = not auto_win and rng.randrange(100) < wound_chance
            if win:
                xp += exp_
                gold += gol
                echo = min(ECHO_CAP, echo + 1)
                if boss:
                    loot += 1
                effective_luck = luck + (ELITE_BONUS_PERCENT if elite else 0)
                if elite or rng.randrange(100) < BASE_DROP_PERCENT + effective_luck * LUCK_DROP_PERCENT:
                    loot += 1
            else:
                echo = 0
            if wounded and "ember_guard" in specials and not ward_spent:
                ward_spent = True
                wounded = False
            if wounded:
                wounds += 1
                echo = (echo + 1) // 2 if "echo_hold" in specials else 0
                if grit > 0:
                    grit -= 1
                else:
                    save = max(5, min(90, DEATH_SAVE_BASE + (stats["ward"] - danger) * 6))
                    if rng.randrange(100) < save:
                        return "broken", xp, gold, loot, wounds
                    kept = (loot + 1) // 2 if "death_writ" in specials else 0
                    return "died", xp, gold, kept, wounds
        if is_final and depth >= 3:
            oxp, ogold = OBJ[zone_id]
            xp += oxp
            gold += ogold
            loot += 1 + (rng.randrange(100) < BASE_DROP_PERCENT + luck * LUCK_DROP_PERCENT)
        else:
            roll = rng.random()
            if roll < 0.35:
                if rng.random() < 0.3:
                    loot += rng.randrange(100) < BASE_DROP_PERCENT + luck * LUCK_DROP_PERCENT
                else:
                    gold += 5 + rng.randrange(11)
            elif roll < 0.55:
                grit = min(grit + 1, grit_max(stats["ward"]))
    return "returned", xp, gold, loot, wounds


def cell(rng, zone_id, depth, level, n, **build):
    from collections import Counter
    outcomes = Counter()
    xp = gold = loot = wounds = 0
    for _ in range(n):
        status, x, g, l, w = run_once(rng, zone_id, depth, level, **build)
        outcomes[status] += 1
        xp += x
        gold += g
        loot += l
        wounds += w
    total = n
    print(f"  {zone_id:15s} depth {depth} @ L{level}: "
          f"death {outcomes['died'] / total:5.1%}  broken {outcomes['broken'] / total:5.1%}  "
          f"returned {outcomes['returned'] / total:5.1%}  "
          f"avg xp {xp / total:6.1f}  gold {gold / total:6.1f}  loot {loot / total:4.2f}  wounds {wounds / total:4.2f}")
    return outcomes


def main():
    n = int(sys.argv[1]) if len(sys.argv) > 1 else 3000
    rng = random.Random(20260926)
    print(f"VESPERBELL balance sim — {n} runs per cell\n")
    print("ZONE / DEPTH PROFILES (assumes typical gear for the level)")
    cell(rng, "marrowfields", 2, 1, n)
    cell(rng, "marrowfields", 3, 2, n)
    cell(rng, "marrowfields", 4, 3, n)
    cell(rng, "marrowfields", 6, 3, n)
    cell(rng, "chime_deep", 3, 3, n)
    cell(rng, "chime_deep", 4, 4, n)
    cell(rng, "chime_deep", 6, 5, n)
    cell(rng, "requiem_scar", 3, 5, n)
    cell(rng, "requiem_scar", 4, 6, n)
    cell(rng, "requiem_scar", 6, 7, n)

    print("\nLANTERN WASTES (two fights per toll)")
    cell(rng, "lantern_wastes", 2, 7, n)
    cell(rng, "lantern_wastes", 4, 8, n)
    print("  With a restored Belfry and both boss relic effects (typical gear stats):")
    cell(rng, "lantern_wastes", 4, 8, n, belfry=(3, 3, 2), specials={"first_strike", "ember_guard"})
    cell(rng, "lantern_wastes", 6, 8, n, belfry=(3, 3, 2), specials={"first_strike", "ember_guard"})

    print("\nPACING: runs of typical depth needed per level (expected xp per run shown above)")
    level = 1
    xp = 0
    runs = 0
    plan = [(1, "marrowfields", 3), (2, "marrowfields", 3), (2, "marrowfields", 4),
            (3, "chime_deep", 4), (4, "chime_deep", 4), (4, "chime_deep", 5), (5, "requiem_scar", 4)]
    for lvl, zone, depth in plan:
        need = XP_THRESHOLDS[min(lvl + 1, MAX_LEVEL)] - xp
        # expected xp for this profile
        exp_xp = 0
        trials = 400
        for _ in range(trials):
            _, x, _, _, _ = run_once(rng, zone, depth, lvl)
            exp_xp += x
        exp_xp /= trials
        need_runs = max(1, round(need / exp_xp)) if need > 0 else 0
        minutes = need_runs * depth * TOLL_SECONDS / 60
        print(f"  L{lvl}: needs {need:4d} xp -> ~{need_runs} runs of {zone} d{depth} (~{minutes:.0f} min)")
        xp = XP_THRESHOLDS[min(lvl + 1, MAX_LEVEL)]


if __name__ == "__main__":
    main()
