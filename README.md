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

### World expansion
- **Briarfen** is the first additional zone after the opening Greenway errand;
- new Briarling enemy family;
- named boss **Old Thornback**;
- second autonomous quest chain;
- guaranteed world-only Rare **Briarheart Charm** boss reward;
- distinct darker wet terrain, thorn props and boss hollow;
- expanded quest/death/recovery state persists and resolves offline.

### Offline continuity
- authoritative save/restore;
- same-simulation offline catch-up;
- duplicate-reward protection;
- concise "While you were away" report;
- debug 10-minute-away simulation;
- temporary 7-day technical catch-up cap while the prototype simulator is still brute-force.

### Equipment slice
- owned gear inventory;
- eight restrained equipment slots;
- inspect and same-slot comparison;
- equip/unequip;
- duplicate-safe sell for gold;
- duplicate-safe salvage for existing gacha tokens;
- guaranteed Goblin Cleaver + Wolfskin Hood during the first quest;
- Gear-banner pulls enter the same owned-gear pool;
- modular visible weapon/armour treatment on the 3D adventurer;
- persistence across saves/offline progress.

### Talent/build slice
- first class: **Wayfarer**;
- three branches: Slayer, Warden and Trailblazer;
- 12 meaningful automatic talents;
- one point per level after level 1;
- prerequisite chains;
- free prototype respec;
- combat, travel and XP effects run in the authoritative simulation;
- talent procs are visible while watching;
- no active combat buttons.

### Companion slice
- one active companion slot;
- activation from the existing Companion collection;
- visible low-poly follower in the watched world;
- distinct passive identities;
- five bond levels from shared kills;
- passive effects run in the authoritative sim and therefore work offline;
- active companion and bond persistence;
- no manual companion abilities or companion-management spreadsheet.

### Gacha collection
- Gear Cache, Companion Pact and Relic Vault;
- 1x and 10x pulls;
- visible hard Legendary pity;
- persistent NEW/copy tracking;
- per-banner collection counts;
- recent summon history;
- favourites and locks;
- locked gear is protected from sell/salvage;
- one token wallet;
- no automatic junk-currency conversion for companion/relic duplicates before those systems exist.

Debug/editor builds expose:
- **Infinite gacha tokens**
- **+10,000 tokens**
- **100-pull stress test**
- **Reset pity counters**

These are development tools, not economy design.

## Art

All 3D art is scripted low-poly, built by Blender from `tools/art/` into `assets/`:

```sh
scripts/build_art.sh
```

The adventurer, goblin and wolf are part-animated models; weapons, hoods, armour and the buckler
show on the adventurer when equipped; the gear drawer uses icons rendered from the same models.
See `docs/ART_PIPELINE.md`.

## Design source of truth

Read `docs/DESIGN_BIBLE.md` for product/roadmap decisions and `docs/ART_STYLE_GUIDE.md` for the locked visual language.

The [mobile genre/player research](docs/MOBILE_GENRE_RESEARCH.md) and [research-backed build backlog](docs/RESEARCH_BACKLOG.md) add 44 scoped tickets for Claude, including generous useful free progression, earned/paid cosmetics, seasonal passes with an archive, optional spending and real guilds, raids, global bosses, PvP and guild wars. Multiplayer is a future direction, not a currently implemented feature. The owner's Android test reports smooth performance and a gear-menu scroll blocker; bespoke portrait UI design and scroll repair are the first verification priority.

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
- hard pity and visible pity reset;
- collection NEW/copy tracking, history cap, favourites/locks and persistence;
- autonomous quest completion;
- travel/combat/quest events;
- loot, XP and level-up;
- death and recovery;
- save/offline parity and duplicate-reward protection;
- gear ownership/equip/disposal and persistence;
- first-quest guaranteed gear;
- Gear gacha → owned equipment integration;
- talent prerequisites, point spending, respec and persistence;
- Slayer/Warden/Trailblazer simulation effects;
- companion activation, passives, bond progression and persistence;
- Briarfen progression, Briarlings, Old Thornback, boss reward and save/load;
- real main-scene launch smoke coverage including collection, talents and visible companion activation;
- every art model loads, and every gear item and companion has a model and icon.

Godot 4.7.2 CI must be green on the exact branch head. Android portrait validation is still required for watchability, touch UX and real suspend/resume behaviour.
