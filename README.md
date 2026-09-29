# VESPERBELL

*Send them into the ash. Listen for the bell.*

A mobile-first idle RPG vertical slice built in **Godot 4.3** (GDScript, portrait,
mobile renderer, zero external assets — every visual is drawn in code and every
sound is synthesized at startup).

You are the Bellkeeper. You name one adventurer and choose where they walk and
how deep. Time passes — close the game, live your life. When you come back, the
bell tells you what happened: what they fought, what nearly killed them, what
they carried home. Loot is the star; the build decisions are real; death costs
the find, never the character.

## The loop

```
SEND OUT (zone + depth)  →  live your life  →  RETURN REPORT ("what did I find?")
   → equip / sell / salvage / temper  →  restore the Belfry  →  push deeper  →  repeat
```

- **3 zones** — The Marrowfields (safe, patient), The Chime Deep (drowned basilica,
  elite Bell-Wardens), The Requiem Scar (the fallen bell, the Gravecho, Requiem-tier loot).
- **Depth is the risk dial** — 2 to 6 tolls. Danger climbs past the third toll.
- **One class (the Bellbound)** with a real identity: **Echo** — every clean kill
  builds +1 Might, every wound silences it. Items and vows bend this rule.
- **Standing orders** — toggle, and they set out again on every return while you
  are away (capped at 24 resolved runs per return).
- **Death** scatters the run's loot and keeps everything else. The thought you
  should have is *"I pushed too far"*, never *"the game punished me."*

## New: the Belfry

The third navigation tab is a permanent home for your progress:

- **Workshop:** restore the Sexton's Anvil (+1 Might/rank, 3 ranks), Vigil Brazier
  (+1 Ward/rank, 3 ranks), and Pilgrim's Candles (+1 Luck/rank, 2 ranks). Spend
  expedition gold and Ashen Shards; these bonuses stack with gear and survive death.
  The bell-yard illustration lights up as you restore it.
- **Milestones:** six always-active, one-time goals reward expeditions, kills,
  safe zone clears, collecting different items, and defeating the Gravecho.
  Claim gold and shards here; a dot on the Belfry tab signals an available reward.
  The Bell screen shows your next goal. No daily resets or expiring rewards.
- **Findings ledger:** discover all 21 items. Only loot actually brought home counts;
  selling or salvaging never erases a discovery. Undiscovered items show road hints.

Upgrades enter the build when you **send out**. An expedition already underway,
including its standing-order chain, retains its original snapshot. Recall and
send out again to use a changed build. Ward upgrades also contribute to Grit.

Existing saves are supported without resetting your hero. Lifetime runs/kills and
currently owned equipment count toward the new goals. Previously sold items and
historical safe zone clears were not recorded, so those are tracked going forward.

Quick way to try it: finish a three-toll expedition, claim **The First Toll** in
Belfry → Milestones, then spend the earnings in **Workshop**. In an editor/debug
build, the desk's **+10 MIN** button skips the wait.

## Running it

Open the project folder in Godot 4.3+ and press Play, or:

```sh
godot --path .
```

The **Bellkeeper's Desk** (time-forward buttons for testing) appears only in
debug builds — in the editor you will see a small "desk" button in the bottom bar.

## Tests

```sh
scripts/run_tests.sh          # content validation + simulation/state + launch smoke tests
GODOT_BIN=/path/to/godot scripts/run_tests.sh
```

The runner uses temporary save data and fails on Godot script errors, even when
the engine exits with status 0. The launch smoke test loads the real main scene
and exercises character creation, navigation, expeditions, reports, equipment,
vows, Belfry purchases/rewards/ledger, and save/resume. Progression tests cover
prices, rank caps, duplicate-claim protection, frozen expedition builds, offline
progress, and old-save migration.

Engine-free checks alone:

```sh
python3 tools/validate_content.py    # cross-references all JSON content
python3 tools/balance_sim.py         # Monte-Carlo of death rates & pacing
```

`tools/balance_sim.py` is a Python mirror of the GDScript expedition rules used
to tune danger/pacing without an engine. If you change constants in
`src/sim/*`, mirror them there and re-run.

## Layout

```
data/            items, zones, enemies, names (JSON, cross-validated at load)
src/sim/         rng, hero math, loot rolls, the expedition engine (pure, deterministic)
src/state/       game store, Belfry progression definitions, save/load
src/data/        content loader + validator
src/ui/          theme, widgets, synth sfx, drawn bell, screens, app shell
tests/           SceneTree simulation/state tests and main-scene launch smoke test
tools/           content validator, balance simulator (Python)
```

Design notes and the full engineering report live in the PR description.
