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

ZONES = {
    "marrowfields": {"danger_base": 1, "enemies": [("reed_shambler", 2, 8, 4), ("mire_lark", 2, 9, 6), ("drowned_tollman", 3, 12, 8)],
                     "weights": {0: 70, 1: 30}, "boss": False},
    "chime_deep": {"danger_base": 2, "enemies": [("echo_wisp", 4, 16, 8), ("sanctified_husk", 5, 20, 11)],
                   "weights": {1: 70, 2: 30}, "boss": False},
    "requiem_scar": {"danger_base": 3, "enemies": [("ash_revenant", 6, 26, 14), ("cinder_hound", 7, 30, 16), ("hollow_deacon", 8, 36, 22)],
                     "weights": {2: 80, 3: 20}, "boss": True},
}
OBJ = {"marrowfields": (30, 25), "chime_deep": (55, 45), "requiem_scar": (90, 80)}
BOSS = ("gravecho", 10, 120, 60)

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


def run_once(rng, zone_id, depth, level, luck_boost=0):
    """Mirror of VbExpedition.resolve. Returns (status, xp, gold, loot_count, wounds)."""
    zone = ZONES[zone_id]
    gear = gear_for(level)
    stats = {k: base_stats(level)[k] + gear[i] for i, k in enumerate(("might", "ward", "luck"))}
    grit = grit_max(stats["ward"])
    echo = 0
    kills = xp = gold = loot = wounds = 0
    combats = 0
    boss_slain = False
    for i in range(depth):
        danger = danger_at(zone, i)
        is_final = i == depth - 1
        # exactly one fight per toll in the mirror (planning mirrors this well enough)
        if is_final and zone["boss"]:
            name, threat, exp_, gol = BOSS
            boss = True
            danger += 4
        else:
            name, threat, exp_, gol = zone["enemies"][rng.randrange(len(zone["enemies"]))]
            boss = False
        combats += 1
        might = stats["might"] + echo
        if (combats - 1) % 3 == 2:
            might += WRATH_BONUS
        win_chance = max(15, min(95, 50 + (might - threat) * 8 - danger * 4))
        win = rng.randrange(100) < win_chance
        wound_chance = max(5, min(85, 30 + danger * 12 - stats["ward"] * 2 - (5 if win else 0)))
        wounded = rng.randrange(100) < wound_chance
        if win:
            kills += 1
            xp += exp_
            gold += gol
            echo = min(ECHO_CAP, echo + 1)
            if boss:
                boss_slain = True
                loot += 1
            luck_eff = stats["luck"] + luck_boost
            if rng.randrange(100) < min(95, BASE_DROP_PERCENT + luck_eff * LUCK_DROP_PERCENT + (30 if boss else 0)):
                loot += 1
        else:
            echo = 0
        if wounded:
            wounds += 1
            echo = 0
            if grit > 0:
                grit -= 1
            else:
                save = max(5, min(90, DEATH_SAVE_BASE + (stats["ward"] - danger) * 6))
                if rng.randrange(100) < save:
                    return "broken", xp, gold, loot, wounds
                return "died", xp, gold, loot, wounds
        # objective at the final toll of a real run
        if is_final and depth >= 3:
            oxp, ogold = OBJ[zone_id]
            xp += oxp
            gold += ogold
            loot += 1  # forced roll
    return "returned", xp, gold, loot, wounds


def cell(rng, zone_id, depth, level, n):
    from collections import Counter
    outcomes = Counter()
    xp = gold = loot = wounds = 0
    for _ in range(n):
        status, x, g, l, w = run_once(rng, zone_id, depth, level)
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
