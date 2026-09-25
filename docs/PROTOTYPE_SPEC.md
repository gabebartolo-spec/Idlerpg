# Smallest Playable Prototype

**Status:** Proposed; requires approval before implementation  
**Current phase:** Research/design only  
**Primary question:**

> Is it exciting to return after being away and discover what the adventurer did and found, then improve them and send them out again?

This document deliberately describes a vertical slice, not the eventual game.

## 1. Recommendation in one paragraph

Build a single-screen-oriented, placeholder-visual prototype in which the player names one adventurer, equips three slots, chooses one of three expedition objectives, closes or backgrounds the game, and returns to a concise report. The report resolves a short deterministic sequence of travel, fights, XP, gold, and a small number of item rolls. The player then equips or sells an item, inspects the event history, chooses a different risk/reward profile when useful, and sends the adventurer out again. Use recoverable defeat rather than permadeath. Use developer-only time controls so the full loop can be tested in seconds without changing the production model.

## 2. Required player loop

### First launch

1. Enter an adventurer name.
2. See a placeholder portrait and the starting equipment.
3. Read one sentence explaining: “Choose a route, leave, and come back to see what happened.”

### At camp

The camp view shows:

- name, level, XP progress, and gold;
- current equipment in weapon, armor, and trinket slots;
- Strike, Guard, and Fortune totals;
- the last few meaningful history entries;
- three route cards with duration, danger, and reward emphasis.

### Departure

The player chooses one route and presses **Send adventuring**. The game records the route, current character/equipment snapshot, start time, and a deterministic seed. The adventurer is unavailable for equipment changes while away.

### While away

The app may be closed, backgrounded, or left open. The simulation does not need to run every second. A small status view can show the planned route and time remaining when the player returns before completion.

### Return

Once the route has completed or the adventurer has retreated, show a report with:

1. time away and route;
2. one outcome headline;
3. grouped event log;
4. XP, level changes, gold, and items;
5. item comparison with **Equip** and **Sell** actions;
6. the next route choice.

Claiming the report must be safe to repeat at the storage level: the rewards must be applied once, even if the app closes between resolution and viewing the report.

## 3. Minimum content budget

The first playable slice should contain no more than the following:

| Content | Minimum |
|---|---:|
| Adventurers | 1 |
| Class | 1 generalist class, or no visible class label |
| Zone | 1 original zone |
| Routes/objectives | 3 |
| Enemy types | 4 |
| Equipment slots | 3: weapon, armor, trinket |
| Player-facing gear stats | 3: Strike, Guard, Fortune |
| Rarity tiers | 3: Common, Uncommon, Rare |
| Authored item templates | 8–10 |
| Level range | 1–5 for the prototype |
| Event templates | 5–7 grouped types |
| Persistent history | 5–10 recent meaningful entries |
| Active expedition | 1 at a time |
| Currency | Gold only |

### Suggested placeholder content

Names are provisional and exist only to make the report testable and memorable.

**Zone:** Bramblewild

**Routes:**

- **Lantern Road:** short and safe; emphasizes gold and common finds.
- **Gloamroot Cavern:** medium risk; emphasizes XP and equipment discovery.
- **Thornwatch Ruins:** dangerous; emphasizes rare loot and has a meaningful retreat chance.

**Enemies:** Mireling, Bristleback, Cave Wisp, Thornback.

**Event types:** travel, enemy encounter, cache/discovery, objective progress, close call/retreat, level-up, return.

The routes should not be three cosmetic labels for the same table. Each should answer a different player need. The names, copy, and item names should be authored rather than procedurally generated so players can remember what they found.

### Timing for the prototype

Use short, human-testable durations such as approximately 1, 5, and 15 minutes. These are tuning values, not a product promise. Add buttons in a development-only panel for “advance 1 minute,” “advance 15 minutes,” and “advance 1 day.” A time-control button is a test tool, not an in-game skip or monetisation mechanic.

The first version should resolve **one finite expedition per send**. Do not add automatic queues, patrol loops, or chained quests until the report and decision are proven. This intentionally tests the core return moment before testing long absence economies.

## 4. Core simulation model

The simulation is a pure, deterministic calculation over saved state and elapsed time.

### Persistent state ownership

The saved game owns:

- schema version;
- adventurer name, level, XP, and gold;
- equipped item IDs and inventory item instances;
- recent history entries;
- active expedition or pending report;
- last known wall-clock timestamp;
- the next adventure sequence number/seed source.

UI nodes do not own authoritative progression values.

### Active expedition

An active expedition contains:

- route ID;
- start timestamp in UTC epoch seconds;
- route seed and adventure sequence ID;
- a snapshot of the adventurer’s level, stats, and equipped item IDs at departure;
- ordered route stages with their durations;
- status: away, resolved, or failed/retreated.

A departure snapshot prevents an item decision made later from retroactively changing a journey.

### Resolution

On load/resume or when the player opens camp:

1. Read the injected current time.
2. Calculate non-negative elapsed seconds from the expedition start.
3. Resolve only route stages whose boundary has been reached.
4. Use the stored seed plus stage index for all random rolls.
5. Stop at a failed combat or at the route’s final stage.
6. Produce a report containing totals and grouped events.
7. Persist the pending report and its resulting state before presenting it.

The prototype does not advance a real-time combat loop while the app is closed. It calculates the same result directly from elapsed time. A small fixed stage list makes the result bounded and easy to inspect; if a later design needs continuous repetition, that should be a separate design decision with aggregate formulas rather than an unbounded loop.

### Combat abstraction

Combat is intentionally not interactive. A combat stage uses:

- the adventurer’s level and Strike;
- the adventurer’s Guard for survival/retreat risk;
- enemy threat and a route modifier;
- one deterministic roll.

The exact formula is a tuning detail, but it must make these statements true and testable:

- more Strike generally improves the pace or chance of winning;
- more Guard makes risky encounters safer;
- Fortune does not silently replace combat power;
- the dangerous route can fail for an underprepared adventurer;
- a failed route produces a clear reason in the report.

A failure is a **defeat and retreat**, not permanent character death. The adventurer keeps some progress already earned and returns unavailable only for the purpose of the current report; there is no injury timer or recovery chore in this slice.

### Rewards and progression

- XP is awarded for completed encounters/objectives.
- Level thresholds are small and hand-authored for levels 1–5.
- A level-up automatically improves the base character enough to be visible in the next route comparison.
- Gold is awarded by routes and some events.
- A successful route yields a bounded equipment roll or named discovery; the player should not receive a flood of disposable items.
- A failed route can retain earlier XP/gold and discoveries but forfeit the final objective reward. The precise split should be tuned so failure is memorable without making players afraid to experiment.

Gold is tracked and selling is supported, but there is intentionally no shop or elaborate gold sink in the first cut. If gold feels inert in playtests, add one small three-choice camp training purchase later; do not add a full economy before the return loop is working.

### Deterministic randomness

Use a small seeded PRNG or equivalent stable integer-roll utility owned by the simulation module. Never use UI timing, frame count, or an unrecorded global random source for an adventure result. The same content, starting snapshot, route, seed, and elapsed time must produce the same report on desktop, Android, iOS, and in a headless test.

This is reproducibility for debugging and trust, not an anti-cheat system.

## 5. Loot and decision design

The first loot table should include clear sidegrades, for example:

- a high-Strike weapon versus a lower-Strike weapon with Fortune;
- a high-Guard armor versus a lighter armor that improves discovery;
- a trinket that makes a rare find more likely versus one that improves safe-route gold.

Each item card must show:

- name, slot, rarity, and one-line identity;
- its two or fewer relevant stat effects;
- deltas against the equipped item;
- a short consequence such as “safer in Thornwatch” or “better chance of an Uncommon find.”

Do not show a single total item score or auto-equip by default. A recommendation may exist later, but the first test needs to observe whether players can make the decision themselves.

Rarity should be infrequent enough to create anticipation and common enough to be observed during testing. Use a debug seed or forced-drop fixture to make every rarity testable without changing ordinary rates.

## 6. Technical recommendation

### Recommended stack

**Godot 4.x stable, GDScript, 2D Control-based UI, local JSON save.** Pin the exact stable patch when implementation begins.

Godot is a good fit because this prototype is mostly menus, cards, labels, and a small amount of placeholder art—not a 3D or networked game. Godot documents desktop, Android, iOS, and web export support, a mobile/compatibility renderer, a headless mode, and a permissive MIT licence. [Godot feature list](https://docs.godotengine.org/en/stable/about/list_of_features.html) · [current release archive](https://godotengine.org/download/archive/)

GDScript is recommended over C# for the prototype because it reduces toolchain friction, is easy for an AI coding session to inspect, and keeps the simulation close to the UI without requiring .NET export decisions. The simulation itself must remain engine-light and avoid scene/node dependencies.

Godot’s `user://` path and `FileAccess`/JSON APIs are sufficient for a local, versioned save. Use a temporary file plus replacement for crash-safe writes rather than letting multiple UI components write independently. [Godot save-game documentation](https://docs.godotengine.org/en/stable/tutorials/io/saving_games.html)

Godot can run headless and execute scripts from the command line, which is sufficient for deterministic simulation tests and later CI. A small test helper or a lightweight testing addon may be added only when the first simulation code exists; no testing framework is needed during this design phase. [Godot command-line documentation](https://docs.godotengine.org/en/latest/tutorials/editor/command_line_tutorial.html)

### Alternatives considered

- **TypeScript + HTML/CSS/Phaser + Capacitor:** attractive for rapid UI iteration and browser distribution, but it adds a web runtime plus native wrapper and makes mobile safe areas, background behavior, and game packaging a second concern. It remains a reasonable fallback if browser-first distribution becomes the primary validation channel. [Phaser mobile guide](https://phaser.io/tutorials/bring-your-phaser-game-to-ios-and-android-with-capacitor)
- **Unity:** technically capable and mature for mobile, but its editor, asset pipeline, and project overhead are unnecessary for a UI-heavy 2D prototype with no networking or 3D. Reconsider only if the visual direction or platform requirements change materially.
- **Flutter:** excellent for application UI, but less natural than Godot for a game-shaped simulation and later game presentation. It would be chosen only if the project becomes primarily a productivity-style app.

The stack is a recommendation, not an irreversible commitment. The simulation API should stay independent enough that a UI technology can be changed without rewriting game rules.

## 7. Proposed architecture

Keep the project small and explicit:

- **Content data:** JSON or similarly plain data files for routes, enemies, items, XP thresholds, and copy. Validate IDs and references on load.
- **Simulation module:** pure value-in/value-out functions for adventure resolution, combat outcomes, progression, loot selection, and report generation.
- **State store:** the single owner of the current `GameState`; exposes narrow commands such as start expedition, resolve, claim report, equip item, sell item, and reset prototype.
- **Save repository:** serializes/deserializes `GameState`, handles schema version and migration, validates corrupted data, and performs atomic writes.
- **Clock/random services:** small injected interfaces used by the state flow and simulation; production uses wall time and the saved seed, tests use fake time and fixed seeds.
- **UI scenes:** create/name, camp, route selection, away status, return report, and inventory. UI renders state and sends commands; it does not calculate rewards.

Do not create an all-purpose `GameManager` containing content, combat, saving, UI, and time. Do not create services, networking, ECS, or account layers for hypothetical future features. One active expedition and one local save are enough.

## 8. Explicit non-goals

Not in the first prototype:

- multiplayer, guilds, parties, raids, PvP, chat, servers, accounts, or cloud sync;
- multiple classes, class abilities, rotations, talent trees, skill loadouts, or party roles;
- multiple zones, open-world navigation, large quest chains, dungeons, or bosses;
- professions, crafting, enchanting, rerolling, salvage, trading, auction houses, or a player economy;
- procedural narrative, generated lore, voice acting, production art, animation, or music;
- real-time combat, manual combat inputs, pathfinding, or a simulated world running every offline second;
- automatic expedition queues, infinite patrol loops, or prestige/endgame layers;
- permanent death, resurrection, injury timers, energy, lives, or recovery chores;
- ads, microtransactions, premium currencies, gacha, paid skips, or monetisation experiments;
- analytics, remote configuration, live events, social features, or anti-cheat systems;
- a full shop or gold economy. Gold must earn its place through playtest evidence first.

The absence of these systems is deliberate. The prototype is allowed to be a small, complete loop.

## 9. Measurable prototype criteria

These are internal decision gates, not claims about commercial benchmarks. Test with a small group of people who have not read the design document, and record both behavior and short explanations.

### Usability and clarity

- At least 8 of 10 testers can name the adventurer, choose a route, and send them without help.
- At least 8 of 10 can explain what happened in the report and identify the most interesting new item or event.
- Median time from opening a completed report to sending the next expedition is between 30 and 90 seconds. Faster is not automatically better if testers are skipping the report; observe comprehension.

### Anticipation and attachment

- At least 7 of 10 testers voluntarily start another expedition after their first report.
- After three loops, at least 6 of 10 can recall one specific event, item name, or close call involving their adventurer.
- At least 6 of 10 say they would want to return to see the result of a route they chose, without being prompted by a reward or monetisation mechanic.

### Meaningful decisions

- In at least half of the sessions, the player equips or keeps a sidegrade for a stated reason other than “the number was higher.”
- At least two routes are selected by meaningful numbers of testers across repeated loops; one route must not dominate solely because it pays the most.
- When asked to predict the consequence of a gear choice, at least 6 of 10 testers can connect Strike, Guard, or Fortune to a route outcome.

### Simulation trust

Automated tests must demonstrate:

- identical inputs, seed, content, and elapsed time produce identical reports;
- closing and reopening at the same time produces the same result as staying open;
- rewards cannot be claimed twice after a simulated interruption;
- negative elapsed time is handled safely;
- a missing, corrupt, or old save fails safely or migrates explicitly;
- XP, gold, inventory, and history remain consistent after every command.

### Interpretation

- **Proceed:** the report is understood and desired, players make at least some contextual gear/route decisions, and the technical state is trustworthy.
- **Iterate:** players understand the loop but do not care about the report or choices. Change report pacing, item identities, route differences, or reward frequency before adding content.
- **Stop or reframe:** players skip the report, always choose the obvious route, treat gear as disposable numbers, or do not send the adventurer out again. More classes, zones, and features would not fix that result.

## 10. Assumptions to test, not facts

1. One named adventurer can create enough attachment without a roster.
2. Reading a report is satisfying even when combat is not interactive.
3. A finite expedition is a better first test than an endless auto-repeat expedition.
4. Three route profiles are enough to create anticipation and planning.
5. Strike, Guard, and Fortune are understandable on a small mobile screen.
6. Players prefer recoverable failure while learning the loop; permanent death may be too costly for this fantasy.
7. A rare but readable item discovery is more exciting than frequent low-value drops.
8. Players will remember authored event and item names.
9. Gold can remain a supporting reward until the loop proves it needs a sink.
10. A 30–90 second return session can feel meaningful without a larger town, story, or social world.
11. Local save and device time are acceptable for an offline-first prototype.
12. Short test expeditions reveal the same emotional pattern that longer overnight expeditions would reveal. This must be revisited after the first loop is credible.

## 11. Implementation sequence after approval

1. **Confirm decisions:** approve or change engine, finite-versus-continuous expedition behavior, failure rule, stat vocabulary, and success gates.
2. **Create content fixtures:** routes, enemies, items, XP thresholds, event copy, and deterministic test seeds.
3. **Build the pure simulation first:** fake clock, seeded rolls, staged resolution, combat, XP, gold, loot, failure, and report generation.
4. **Write simulation tests:** elapsed-time boundaries, deterministic replay, loot/rarity, level-ups, failure, and report idempotency.
5. **Add the versioned local save:** JSON serialization, validation, atomic write, load recovery, and one state owner.
6. **Build the vertical UI:** name creation → camp → route selection → away status → return report → equip/sell → next route.
7. **Add developer controls:** time advance, seed selection, forced rarity, forced failure, clear save, and report replay. Keep them out of release builds.
8. **Tune for the return moment:** headline ordering, event grouping, drop frequency, route differences, and report length.
9. **Run the defined playtest:** observe behavior before adding content or systems; record why players equip, sell, or choose a route.
10. **Decide the next experiment:** improve the loop, test longer offline durations, or stop. Do not expand toward MMO systems merely because the prototype is technically functional.

No implementation should begin until the user approves this scope and the unresolved decisions above.
