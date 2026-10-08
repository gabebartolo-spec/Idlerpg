"""Frozen raid rules. All starter roles contribute; equipment is server-owned."""
import copy

VERSION = 1
BUILDS = {
    "trail": {"hp": 45, "attack": 12, "shield": 10, "heal": 5},
    "thornward": {"hp": 55, "attack": 10, "shield": 16, "heal": 5},
    "keeper": {"hp": 50, "attack": 18, "shield": 12, "heal": 7},
}
ROLES = ("damage", "protection", "preparation")
BOSS = {"name": "The Hollow Warden", "hp": 120, "attack": 30, "armour": 8, "seals": 3, "rounds": 10}


def rules():
    return {"version": VERSION, "boss": copy.deepcopy(BOSS), "gold": 60, "look": "warden_lantern"}


def resolve(roster, frozen_rules):
    """Deterministic bounded auto-fight. No network, wall clock or RNG input."""
    boss = frozen_rules["boss"]
    max_hp = sum(member["stats"]["hp"] for member in roster)
    hp = max_hp
    enemy = boss["hp"]
    seals = boss["seals"]
    contribution = {m["account"]: {"damage": 0, "prevented": 0, "healed": 0, "seals": 0} for m in roster}
    rounds = []
    won = False
    for turn in range(1, boss["rounds"] + 1):
        armour = boss["armour"] if seals else 0
        preparation = next((m for m in roster if m["role"] == "preparation"), None)
        if preparation and seals:
            seals -= 1
            contribution[preparation["account"]]["seals"] += 1
        attacks = [(m, m["stats"]["attack"] if m["role"] == "damage" else 3) for m in roster]
        # Armour is a single party-wide reduction; distribute effective hits
        # consistently for recap totals rather than giving the first role credit.
        remaining_armour = armour
        for member, hit in attacks:
            absorbed = min(hit, remaining_armour)
            remaining_armour -= absorbed
            dealt = min(max(enemy, 0), hit - absorbed)
            enemy -= dealt
            contribution[member["account"]]["damage"] += dealt
        if enemy <= 0 and seals == 0:
            won = True
            rounds.append({"round": turn, "party_hp": hp, "boss_hp": 0, "seals": seals})
            break
        protection = next((m for m in roster if m["role"] == "protection"), None)
        shield = min(boss["attack"], protection["stats"]["shield"]) if protection else 0
        if protection:
            contribution[protection["account"]]["prevented"] += shield
        hp = max(0, hp - (boss["attack"] - shield))
        if preparation and hp > 0:
            healing = min(max_hp - hp, preparation["stats"]["heal"])
            hp += healing
            contribution[preparation["account"]]["healed"] += healing
        rounds.append({"round": turn, "party_hp": hp, "boss_hp": max(enemy, 0), "seals": seals})
        if hp <= 0:
            break
    return {"won": won, "rules_version": frozen_rules["version"], "rounds": rounds, "contributions": contribution, "reason": "Warden defeated" if won else ("Lantern seals remain" if seals else "Party overwhelmed")}
