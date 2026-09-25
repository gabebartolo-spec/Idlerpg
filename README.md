# Idlerpg

A research-stage design for a small, original-IP idle RPG built around one promise:

> **A little adventurer goes off and plays an RPG while I am away.**

The player sends the adventurer into a simulated expedition, returns later to discover what happened, reviews the loot, makes one or two meaningful decisions, and sends them out again.

## Current phase

**Approved prototype implementation — first playable vertical slice in progress; runtime validation pending.**

The approved prototype implementation is intentionally small and uses placeholder UI/assets. Godot 4.x project files, deterministic simulation, local persistence, automated test scripts, and the send/return/equipment loop are present. The local sandbox does not currently include a Godot executable, so engine execution still needs to be performed in a Godot 4.x environment before the prototype can be declared runtime-verified.

Do not add production art, monetisation, networking, or long-term MMO systems until this prototype has been reviewed through human playtesting.

## Documents

- [`docs/RESEARCH_AND_DESIGN.md`](docs/RESEARCH_AND_DESIGN.md) — research notes, evidence, opportunities, risks, and design principles.
- [`docs/PROTOTYPE_SPEC.md`](docs/PROTOTYPE_SPEC.md) — proposed smallest playable prototype, simulation model, technical approach, scope boundaries, success criteria, and implementation sequence.

## Running the prototype

From a machine with Godot 4.x installed:

```bash
godot --path .
./scripts/run_tests.sh
```

If the executable is not named `godot` or is not on `PATH`, use `GODOT_BIN=/path/to/godot ./scripts/run_tests.sh`.

## Primary question

> **Is it exciting to return after being away, discover what the adventurer did and found, improve them, and send them out again?**

The first prototype is a test of that return loop, not a miniature MMO.
