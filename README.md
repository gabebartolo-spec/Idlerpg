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
   → equip / sell / salvage / temper  →  (vow, sometimes)  →  push deeper  →  repeat
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

## Running it

Open the project folder in Godot 4.3+ and press Play, or:

```sh
godot --path .
```

The **Bellkeeper's Desk** (time-forward buttons for testing) appears only in
debug builds — in the editor you will see a small "desk" button in the bottom bar.

## Tests

```sh
scripts/run_tests.sh          # content validation + full GDScript suite
GODOT_BIN=/path/to/godot scripts/run_tests.sh
```

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
src/state/       game store (verbs + offline chain resolution), save/load
src/data/        content loader + validator
src/ui/          theme, widgets, synth sfx, drawn bell, screens, app shell
tests/           SceneTree test runner (26 tests / ~80 checks)
tools/           content validator, balance simulator (Python)
```

Design notes and the full engineering report live in the PR description.
