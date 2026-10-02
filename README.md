# Idle RPG — fresh start

A mobile-first **WoW Tamagotchi**: raise, equip and shape a persistent adventurer who lives in a simplified low-poly 3D MMO-like world whether or not you are watching.

The authoritative simulation owns what happens. The 3D world visualises it. There is no manual combat.

## Current prototype

### Living adventurer slice
- one low-poly test zone;
- Mossgate town, Goblin Camp and Wolf Den;
- autonomous travel;
- two mob types;
- automatic combat;
- loot and XP;
- level-up;
- one repeating quest chain;
- death and recovery;
- compact current-activity / quest UI;
- following watch camera.

The first quest is intentionally tiny: leave Mossgate, defeat three goblins, travel to the wolves, defeat two, return to town, collect the reward, rest, then head out again.

### Offline continuity
- authoritative save/restore;
- same-simulation offline catch-up;
- duplicate-reward protection;
- concise "While you were away" report;
- debug 10-minute-away simulation;
- temporary 7-day technical catch-up cap while the prototype simulator is still brute-force.

### Equipment slice
- owned gear inventory;
- weapon/head/chest/off-hand slots;
- equipped items change combat stats;
- guaranteed Goblin Cleaver + Wolfskin Hood during the first quest;
- Gear-banner pulls enter the same owned-gear pool;
- equipped weapons visibly change on the 3D adventurer;
- persistence across saves/offline progress.

### Gacha foundation
- Gear Cache;
- Companion Pact;
- Relic Vault;
- 1x and 10x pulls;
- simple Legendary pity;
- one token wallet.

Debug/editor builds expose:
- **Infinite gacha tokens**
- **+10,000 tokens**
- **100-pull stress test**
- **Reset pity counters**

These are development tools, not economy design.

## Design source of truth

Read `docs/DESIGN_BIBLE.md`.

The central rule is:

> The simulation is the game; 3D is its window.

Watched and offline play must eventually consume the same authoritative state/events rather than running separate combat logic.

## Next gate

Do **not** broaden the content yet.

1. Keep the current PR green in Godot 4.7.2 CI.
2. Run it on Android portrait.
3. Judge whether watching the adventurer run, fight, loot and complete the tiny quest is actually charming.
4. Verify real suspend/resume catch-up and the Gear/equip drawer on the phone.
5. Fix core-loop/mobile blockers before adding more zones/classes/content.

The old Vesperbell implementation remains recoverable from Git history. It should not be copied forward wholesale.

## Tests

```sh
scripts/run_tests.sh
```

Current targeted tests cover:
- normal gacha token spending;
- insufficient funds;
- debug infinite-token pulls;
- 100-pull stress usage;
- hard pity;
- autonomous quest completion;
- travel/combat/quest events;
- loot, XP and level-up;
- death and recovery;
- save/offline parity and duplicate-reward protection;
- gear ownership/equip stat changes and persistence;
- first-quest guaranteed gear;
- Gear gacha → owned equipment integration;
- real main-scene launch smoke coverage.

This branch still needs actual Godot 4.7.2 runtime validation. Static repository inspection is not a passing build.
