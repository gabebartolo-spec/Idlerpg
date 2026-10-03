# Idle RPG — Roadmap & Design Bible

**Working description:** a mobile-first **WoW Tamagotchi**: raise, equip and shape a persistent adventurer who lives in a simplified 3D MMO-like world whether or not you are watching.

**Engine:** Godot 4.7.2  
**Primary platform:** Android portrait  
**Status:** pre-production / clean-slate prototype  
**Source of truth:** this document defines the intended product unless a newer explicit decision supersedes it.

---

# 0. North star

## The one-sentence pitch

**Build an adventurer, send them into a small living fantasy world, and watch them quest, grind, loot, die, recover and grow — without ever controlling the combat directly.**

The player is not the adventurer's hands. The player is their **coach, quartermaster, talent planner, collector and caretaker**.

The best recurring thought should be:

> “I wonder what my little idiot has been doing.”

The game should create attachment to one persistent character in the way a Tamagotchi creates attachment to a creature, while delivering the progression fantasy of an MMO character.

---

# 1. Product pillars

## 1.1 A persistent little adventurer

The character must feel like a person occupying a world, not a progress bar wearing a portrait.

At any moment they should have understandable state:
- where they are;
- where they are going;
- what quest they are pursuing;
- what they are fighting;
- what they recently looted;
- whether they are healthy, injured, dead, resting or returning;
- what gear/build they are using;
- what they have accomplished recently.

When the player returns after time away, the game should answer **“what happened to them?”**, not only “you gained 3.6K XP.”

## 1.2 Watchable, never manually controlled

Everything the character does should be watchable in 3D:
- running between locations;
- entering villages/camps;
- seeking quest targets;
- fighting mobs;
- looting;
- interacting with simple quest objects;
- resting or recovering;
- returning to town;
- eventually joining dungeon/party/raid groups.

Watching is optional.

There is **no movement joystick, attack button, dodge button, spell rotation or tap-to-win combat**.

The player influences outcomes through preparation and long-term decisions:
- equipment;
- talents;
- skill choices;
- consumable loadout;
- quest/zone priorities;
- companions;
- professions;
- later party composition and high-level behavioural policies.

## 1.3 The simulation is the game; 3D is its window

The world simulation must run independently from presentation.

The same authoritative state should be able to resolve:
- while the app is open and the player is watching;
- while the app is open on a management screen;
- while the app is closed and time is resolved on return.

The 3D layer **visualises authoritative simulation events**. It must never become a second combat engine with different results.

If an offline result says the adventurer killed a goblin, watching that same event should show the goblin fight. Rendering should not reroll it.

## 1.4 MMO progression without MMO obligations

The fantasy should borrow the satisfying structure of a theme-park MMO:
- zones;
- quests;
- levels;
- classes/builds;
- gear rarity;
- bosses;
- professions;
- dungeons;
- parties;
- guilds;
- raids;
- long-term endgame progression.

But the game is **not an MMO**. Other adventurers can be simulated NPCs. There is no need to solve networking, matchmaking or synchronous social systems for the core game.

## 1.5 Gacha should be exciting and abundant

Gacha is a major collection/progression pillar, not a tiny side mechanic.

Potential banner families:
- gear;
- companions;
- relics;
- cosmetics;
- mounts later;
- profession helpers or specialist followers later.

The prototype should favour **lots of pulls and lots of experimentation**. The fun is collection, surprise, build discovery and visible character change.

Do not begin with a predatory economy. Monetisation is a later product decision. The prototype must first prove that pulling is fun when test currency is effectively unlimited.

## 1.6 Management should matter

The player should be able to make meaningful decisions without needing constant attention.

Core management:
- equipment;
- inventory;
- talent/skill trees;
- build presets later;
- quest/zone choice;
- gacha collection decisions;
- companions;
- professions;
- optional minigames.

A good session can be 30 seconds:
1. see what happened;
2. equip an upgrade;
3. spend a talent point;
4. send the adventurer onward.

A longer session can involve:
- comparing builds;
- watching an expedition;
- sorting loot;
- doing a minigame;
- pulling gacha;
- preparing for a boss/dungeon.

---

# 2. Explicit non-goals

These are important because the old prototype expanded before the core fantasy was proven.

Do **not** build these early:

- manual combat;
- virtual joystick movement;
- dodge/parry timing;
- a giant bespoke lore setting before the loop works;
- dozens of zones before one zone feels alive;
- hundreds of items before gear decisions are interesting;
- a fully simulated open world;
- real multiplayer;
- guild chat;
- PvP;
- elaborate crafting trees;
- housing;
- hunger/thirst/toilet chores;
- mandatory daily check-ins;
- energy systems that stop play;
- eleven premium currencies;
- battle passes/live ops before retention exists;
- 3D fidelity that compromises Android performance.

“Tamagotchi” means **attachment and persistence**, not maintenance punishment.

---

# 3. Core loop

## 3.1 The macro loop

1. **Check in**
   - See the character in the world.
   - Read a concise “since you were away” story.
   - See meaningful rewards/deaths/quest progress.

2. **Review**
   - Inspect loot.
   - Compare equipment.
   - Spend talent/skill points.
   - Claim useful gacha resources.
   - Make only the decisions that matter.

3. **Prepare**
   - Equip.
   - Choose or continue a quest/zone.
   - Set companion/consumables later.
   - Adjust build if desired.

4. **Send / continue**
   - The character resumes their life.
   - The player can leave immediately.

5. **Watch optionally**
   - Observe travel, fights, quest progress and returns.
   - Hide most UI for a relaxed “little guy doing his thing” mode.

6. **Grow**
   - Levels, gear, talents, collections and world access accumulate.
   - New content expands what the character can autonomously attempt.

## 3.2 The micro simulation loop

The character repeatedly cycles through understandable jobs:

**Choose task → travel → encounter/interact → resolve → loot/progress → choose next task**

Examples:
- travel to boar field → kill boars → collect tusks → return to quest giver;
- run to mine → gather ore → get attacked → continue mining → return to town;
- travel to dungeon entrance → join NPC party → clear rooms → fight boss → return;
- visit trainer → learn unlocked passive → continue questing.

This state machine should remain legible enough that the UI can always answer:
- “What are they doing?”
- “Why are they doing it?”
- “What happens next?”

---

# 4. The adventurer

## 4.1 One character first

The first version is about attachment to **one main adventurer**.

Do not begin with a roster-management game.

Later systems may introduce:
- companions;
- NPC party members;
- alts;
- apprentices/heirs;
- guild members.

But the emotional centre remains the player's adventurer.

## 4.2 Character identity

Minimum:
- player-chosen name;
- class;
- level;
- visible equipment;
- current activity;
- current zone;
- recent history.

Possible later identity:
- appearance customisation;
- titles;
- favourite enemy/zone stats;
- scars/death history;
- notable drops;
- boss kills;
- profession specialities;
- relationship with recurring NPCs.

Avoid fake personality meters until there is a gameplay reason for them.

## 4.3 Classes

Start with **one class** until the loop is proven.

The first class should demonstrate:
- resource use;
- several meaningful passive branches;
- visible gear changes;
- different viable builds.

Do not build five classes just to populate a class-select screen.

Class expansion happens only after:
- combat simulation is stable;
- itemisation supports archetypes;
- talent choices actually alter outcomes.

---

# 5. World and watch mode

Production visuals must follow `docs/ART_STYLE_GUIDE.md`, which locks the original low-poly heroic-fantasy language, mobile budgets, modular gear treatment and generated-asset consistency rules.


## 5.1 Visual target

Aim for **readable low-poly 3D MMO nostalgia**, not an exact imitation of any existing game's assets or world.

Desired qualities:
- simple silhouettes;
- bright/readable equipment;
- chunky weapons;
- small scenic zones;
- clear paths;
- stylised low-poly trees/rocks/buildings;
- exaggerated attack tells;
- modest texture requirements;
- strong performance on mid-range Android devices.

The game should look pleasant from a slightly elevated MMO-style camera without demanding expensive animation or shaders.

## 5.2 World structure

Prefer **small connected zones** over one huge seamless world.

A zone may contain:
- a town/camp;
- paths;
- two or three mob areas;
- quest NPC locations;
- one landmark;
- a boss/event location;
- resource nodes later.

This keeps pathfinding, simulation, authoring and Android performance tractable.

Travel between zones can initially be an abstract transition rather than a seamless continent.

## 5.3 Watch camera

Initial camera:
- fixed/elevated third-person follow;
- enough distance to understand surroundings;
- automatic framing for combat;
- no required camera input.

Later options:
- tap character to focus;
- simple orbit;
- cinematic boss camera;
- “follow closely” / “overview” toggle.

Watch mode should be relaxing, not a camera-management task.

## 5.4 World activity

The world should feel occupied without simulating an MMO server.

Cheap ambience:
- NPCs walking simple routes;
- other adventurers represented by lightweight local agents;
- mobs wandering within territories;
- quest-giver idle animations;
- distant combat as non-authoritative ambience.

Only the player's authoritative simulation needs full persistence.

---

# 6. Authoritative simulation model

This is a non-negotiable architecture rule.

## 6.1 State, events, presentation

Use three layers:

### State
Persistent truth:
- character stats/build;
- inventory/equipment;
- location;
- current task;
- quest state;
- health/resource;
- timers;
- RNG state/seed where useful;
- rewards already granted.

### Simulation
Advances state and emits events:
- travelled;
- encounter started;
- attack resolved;
- damage taken;
- mob killed;
- item dropped;
- quest objective advanced;
- level gained;
- death;
- respawn;
- task completed.

### Presentation
Consumes events/state and shows:
- movement;
- animations;
- floating damage sparingly;
- loot pickup;
- quest marker changes;
- death/respawn;
- concise report text.

Presentation must never decide whether an attack hits or what loot drops.

## 6.2 Offline progression

On suspend/close:
- save authoritative state;
- save wall-clock timestamp;
- no rendering assumptions.

On return:
- calculate elapsed time;
- advance simulation efficiently;
- produce a concise event summary;
- preserve important narrative events rather than dumping every attack.

Offline progression should not punish players for staying away.

If an eventual cap is needed for economy/performance, it should be generous and clearly justified — not a FOMO mechanic.

## 6.3 Watched/offline parity

Core acceptance rule:

Given equivalent starting state and elapsed simulation time, watched and un-watched resolution should produce equivalent authoritative outcomes.

Animation timing can differ from simulation granularity. Results cannot.

---

# 7. Combat

## 7.1 Player relationship to combat

Combat is **observed and prepared for**, not directly controlled.

The player changes combat by:
- stats;
- equipment;
- talents;
- companion choice;
- consumable rules later;
- target/zone selection;
- build priorities.

The player does not:
- press attacks;
- manually cast abilities;
- dodge attacks;
- aim.

## 7.2 First combat model

Keep the first model small:
- health;
- attack power;
- defence;
- attack interval;
- crit;
- one class resource if useful;
- a few passive/automatic abilities.

Under the hood, combat may be event/tick based.

The visual layer turns those events into readable attacks.

## 7.3 Death

Death should create stories without destroying attachment.

Default direction:
- character respawns/recovers;
- durability or small time penalty may apply later;
- some unbanked expedition rewards may be at risk if that creates useful tension;
- permanent character loss is not part of the base game.

A death should make the player think:
**“I pushed too far / my build needs work.”**

Not:
**“The game deleted my pet.”**

## 7.4 Enemy design

Enemies need functional identity before huge variety.

Early families might demonstrate:
- basic melee;
- fragile ranged;
- slow heavy hitter;
- evasive/fast;
- elite/boss.

Visual silhouette and combat behaviour should align.

---

# 8. Quests

## 8.1 Purpose

Quests give autonomous activity meaning.

Without quests, the character risks feeling like a grinder walking between spawn points.

## 8.2 First quest types

Start with:
- kill N enemies;
- collect N drops;
- travel to location;
- interact with an object;
- defeat a named mob.

Combine these into short chains.

## 8.3 Quest automation

The character should know how to pursue an accepted quest:
- path toward relevant area;
- select valid targets;
- collect objective drops;
- return/advance when complete.

The player can choose which quest or zone matters. They should not micromanage every leg.

## 8.4 Quest presentation

Show:
- current quest;
- plain-English current objective;
- progress;
- why the character is travelling somewhere.

Avoid a giant MMO quest tracker.

---

# 9. Equipment and itemisation

## 9.1 Equipment is core active gameplay

Gear should be one of the main reasons to check the game.

Early slots:
- weapon;
- head;
- chest;
- legs;
- hands;
- feet;
- one accessory.

Do not start with twenty slots.

## 9.2 Item goals

An item should be understandable quickly:
- is this stronger?
- what build does it support?
- is its rare effect interesting?
- do I want to keep, equip, salvage or feed it into another system?

Avoid stat soup.

## 9.3 Rarity

Prototype rarity:
- Common;
- Rare;
- Epic;
- Legendary.

Rarity should alter more than colour eventually:
- affix count;
- unique effects;
- visual treatment;
- build-defining possibilities.

## 9.4 Visual equipment

A major benefit of 3D:
**equipping something should visibly change the little adventurer whenever practical.**

Weapons are highest priority.
Armour silhouettes/colour changes follow.
Do not require bespoke meshes for every prototype item.

---

# 10. Talents and skills

## 10.1 Purpose

Talents are how the player coaches the adventurer.

The tree should create distinct automatic behaviours/builds without requiring active buttons.

Examples:
- more frequent heavy attacks;
- bleed build;
- defensive recovery;
- crit chain;
- execute;
- resource generation;
- companion synergy.

## 10.2 Shape

Prefer a small branching tree with meaningful nodes over dozens of +1% filler nodes.

First target:
- roughly 12–20 meaningful nodes;
- several mutually interesting routes;
- low-cost respec during development.

## 10.3 Active-looking, automatically used abilities

Abilities can look active in combat while remaining automatic.

Example:
- “Whirlwind triggers when surrounded by 3+ enemies.”
- “Execute automatically fires below 20% enemy health.”
- “Shield Wall triggers below 30% health with a cooldown.”

This creates readable spectacle without manual combat.

---

# 11. Gacha

## 11.1 Role

Gacha should supply **collection excitement and build possibilities**, not replace every other reward source.

The world must still drop meaningful loot.

Gacha can provide:
- alternative gear;
- rare gear;
- companions;
- relics;
- cosmetics;
- later mounts.

## 11.2 Prototype banners

The clean prototype begins with:
- Gear Cache;
- Companion Pact;
- Relic Vault.

These are scaffolding, not final names or final economy.

## 11.3 Pull feel

Pulling should be fast and satisfying:
- x1 and x10;
- clear rarity reveal;
- no long unskippable animation;
- good multi-pull summary;
- easy “new” identification;
- immediate inspect/equip path.

Later:
- x50 / skip animation;
- wishlists or targeted banners;
- collection book;
- banner history.

## 11.4 Pity

A pity system should be visible and understandable.

Prototype:
- simple hard Legendary pity.

Later design can add:
- soft pity;
- featured guarantee;
- banner-specific pity;
- carry-over rules.

Do not create opaque casino math.

## 11.5 Duplicates

Duplicates must not feel completely dead.

Possible later uses:
- salvage currency;
- item awakening;
- cosmetic variants;
- collection mastery.

Avoid systems where a character/item is useless until six duplicates are pulled.

## 11.6 Currency

Keep the economy legible.

Early:
- gold for ordinary world economy;
- one gacha token/currency.

Only add currencies when they solve a real design need.

## 11.7 Development tools

Debug/editor builds must keep:
- Infinite gacha tokens;
- +10,000 tokens;
- 100-pull stress test;
- pity reset;
- later: force rarity / force featured result;
- later: export pull statistics.

Dev tools must be impossible to rely on in release builds.

---

# 12. Companions

Companions are a strong fit for both Tamagotchi attachment and gacha.

They can:
- follow visibly;
- provide passive combat roles;
- change loot/profession behaviour;
- have simple progression;
- create collection goals.

Do not introduce a full second equipment/talent game for every companion early.

First companion system should be:
- one active companion slot;
- clear passive/combat identity;
- visible follower;
- simple level or bond progression.

---

# 13. Professions and minigames

## 13.1 Why minigames exist

Minigames are the primary home for **optional active gameplay**.

They give the player something tactile to do without compromising the “no manual combat” rule.

## 13.2 Candidates

Strong early candidates:
- fishing;
- mining;
- smithing;
- cooking;
- archaeology/treasure hunting.

## 13.3 Design rule

Every profession should work passively at a basic level.

A minigame can provide:
- efficiency;
- bonus quality;
- extra materials;
- temporary buffs;
- cosmetic/mastery rewards.

The player should never feel forced to play a twitch minigame every day to keep progression viable.

## 13.4 First minigame

Build only one after the core quest/combat loop is proven.

Fishing is a good candidate because it:
- fits idle and active play;
- can be visually relaxing;
- supports collection;
- can feed cooking/consumables later.

---

# 14. Towns, vendors and downtime

Towns make the character feel like they inhabit a world.

Early town functions:
- quest giver;
- vendor;
- trainer/talent access;
- stash;
- respawn/rest point;
- gacha access can remain UI-level rather than requiring an in-world machine.

The character can visibly return to town, but management screens should not require physically waiting for them unless that waiting is meaningful.

---

# 15. Dungeons, parties and raids

These are later pillars, not prototype scope.

## 15.1 Dungeons

A dungeon is a longer autonomous job:
- travel to entrance;
- form/join simulated party;
- clear encounters;
- boss;
- loot;
- return.

The player's decisions are preparation and party/build choices.

## 15.2 Simulated party members

NPC adventurers can create MMO texture:
- tank;
- healer;
- damage;
- support.

Their behaviour should be deterministic enough to understand but varied enough to create stories.

## 15.3 Raids

Raids are endgame build checks and spectacle.

They should not be built until:
- combat is readable;
- gear progression works;
- party simulation works;
- boss mechanics can influence auto-build decisions.

A raid should test preparation, not reaction speed.

---

# 16. UI / UX

## 16.1 Mobile-first layout

Portrait is the primary format.

Default screen should prioritise the world.

Suggested composition:
- most of screen: 3D world;
- compact top status;
- bottom navigation or expandable management drawer;
- contextual activity/quest line;
- optional full-screen watch mode.

## 16.2 Information hierarchy

At a glance:
- what is my adventurer doing?
- are they okay?
- did something important happen?
- do I have a meaningful decision waiting?

Everything else can be drilled into.

Avoid:
- dashboards full of currencies;
- five simultaneous quest panels;
- tiny MMO hotbars;
- PC inventory grids shrunk onto a phone;
- notification-dot spam.

## 16.3 Return report

The return report is critical.

It should read like:
- 3 quests progressed;
- 18 enemies killed;
- reached level 9;
- died once to the cave troll;
- found an Epic bow;
- brought home 420 gold.

Then offer direct actions:
- inspect new loot;
- spend point;
- watch current activity;
- close report.

The report should surface stories, not dump an event log.

---

# 17. Audio

Audio should make spectating pleasant.

Early priorities:
- footsteps;
- weapon impacts;
- enemy hit/death;
- loot pickup;
- level-up;
- ambient zone loop;
- restrained music.

Do not build a large soundtrack before the loop works.

The game should remain comfortable to leave open beside the player.

---

# 18. Economy principles

The economy exists to support decisions and collection.

Early resources:
- gold;
- gacha token.

Later candidates:
- crafting materials;
- profession resources;
- salvage essence.

Before adding any currency, answer:
**What decision does this currency create that gold cannot?**

No mandatory daily energy.
No artificial “come back in 17 minutes” gate just to manufacture retention.

---

# 19. Save and persistence rules

The character's life is the product. Save loss is catastrophic.

Requirements:
- automatic save after important state changes;
- safe save on app suspend;
- schema versioning from the beginning;
- migration tests when persistent structure changes;
- offline elapsed-time handling must tolerate clock anomalies;
- duplicate reward protection;
- no rerolling gacha or loot by force-closing.

Cloud save can be investigated later. Local robustness comes first.

---

# 20. Content philosophy

## 20.1 Small world, deep reuse

Prove systems with tiny content counts.

One good zone is more valuable than four dead zones.

One boss that makes the player rethink their build is more valuable than ten stat sticks.

## 20.2 Data-driven where it earns its keep

Use data resources/tables for content that will genuinely scale:
- items;
- enemies;
- quests;
- banners;
- zones.

Do not create a generic content framework for hypothetical systems.

## 20.3 Original identity later, generic readability first

The old prototype spent too much effort on bespoke “Vesperbell” identity before the product loop was settled.

For early prototypes, readable fantasy placeholders are acceptable.

Once the loop earns investment, create an original setting/art identity intentionally.

---

# 21. Analytics for development

Useful development questions:
- How long until the first gear decision?
- How often does the character die?
- How much time is spent travelling vs fighting?
- How many meaningful upgrades appear per hour?
- Which talent routes are used?
- How many pulls until a useful result?
- How long do players voluntarily watch?
- Do players understand what their adventurer is doing?
- Is offline progress understandable on return?

Do not optimise monetisation metrics before fun/retention fundamentals exist.

---

# 22. Testing strategy

## 22.1 Simulation tests

Core deterministic tests:
- travel completes;
- encounters resolve;
- quest objectives advance;
- rewards grant exactly once;
- death/respawn works;
- offline resolution matches watched authoritative outcomes;
- save/load preserves activity;
- item equip modifies simulation correctly.

## 22.2 Gacha tests

- currency spending;
- insufficient funds;
- rarity distribution sanity;
- pity;
- duplicate handling;
- banner isolation/carry-over rules;
- debug infinite tokens;
- release builds cannot access debug cheats.

## 22.3 Mobile tests

Every major milestone must be tried on Android:
- portrait readability;
- touch targets;
- frame rate;
- memory;
- suspend/resume;
- offline return;
- battery/thermal behaviour during watch mode.

## 22.4 Long-run tests

Eventually simulate:
- hours;
- days;
- weeks of progression.

Watch for:
- runaway stat inflation;
- dead progression bands;
- economy overflow;
- impossible quest state;
- stuck pathing/task state;
- duplicate rewards;
- unusable inventories.

---

# 23. Roadmap

The roadmap is intentionally gated. **Do not begin later phases just because they sound fun.**

## IRPG-P0 — Clean foundation

**Status:** `VERIFY` — implemented in PR #4; focused Godot 4.7.2 CI is green, Android phone validation still required.  
**Goal:** replace the Arena/Vesperbell prototype with a minimal Godot 4.7 mobile foundation.

Scope:
- clean repository tree;
- portrait/mobile project config;
- primitive low-poly 3D scene;
- reusable gacha state;
- Gear / Companion / Relic test banners;
- debug infinite tokens;
- basic gacha test.

Exit gate:
- project opens in Godot 4.7.2 without script errors;
- runs on Android;
- dev infinite-token tools work;
- primitive 3D scene renders acceptably on phone.

Do not add content breadth inside this phase.

---

## IRPG-P1 — The living adventurer vertical slice

**Status:** `VERIFY` — implemented in PR #4; headless launch/simulation tests are green, phone watchability check still gates P2.  
**Priority:** CRITICAL  
**Goal:** prove the actual game.

Build:
- one small 3D zone;
- one town/respawn point;
- one adventurer;
- automatic task state machine;
- visible navigation between points;
- two basic enemy types;
- autonomous combat;
- one simple quest chain;
- drops;
- XP and level-up;
- death and recovery;
- concise current-activity UI.

Required simulation states:
- idle;
- travelling;
- fighting;
- looting;
- interacting;
- returning;
- dead/recovering.

Acceptance:
- open the app and immediately understand what the adventurer is doing;
- the character visibly runs to a quest objective;
- fights a mob without player input;
- loots;
- advances the quest;
- returns/continues;
- player can watch the whole thing without touching combat controls;
- no manual combat exists.

**Implementation (PR #4):** Mossgate, Goblin Camp and Wolf Den are present in the primitive 3D world. The adventurer autonomously travels, fights three goblins and two wolves, loots, gains XP/levels, returns for the quest reward, rests and repeats. Death returns the persistent character to Mossgate for recovery. The 3D layer reads simulation state rather than resolving combat itself. A focused launch smoke test instantiates the real main scene in Godot 4.7.2 CI.\n\n**Hard gate:** if watching this is not at least mildly charming on the phone, do not build the MMO feature stack. Fix this first.

---

## IRPG-P2 — Offline parity

**Status:** `VERIFY` — implemented in PR #4; save/restore, same-simulation offline catch-up, duplicate-reward protection and return-report tests are green. Real Android suspend/resume still requires phone validation.  
**Priority:** CRITICAL  
**Goal:** prove that the game exists while closed.

Build:
- authoritative timestamped state;
- efficient offline simulation;
- event summarisation;
- suspend/resume save;
- return report.

Acceptance:
- start a quest and close the app;
- reopen later;
- the adventurer has progressed exactly through legal simulation states;
- important rewards/deaths/levels are summarised;
- no duplicate rewards;
- equivalent watched/unwatched runs produce equivalent authoritative results.

**Implementation (PR #4):** the app checkpoints authoritative adventurer + gacha state, advances the saved adventurer through the same simulation on return, immediately checkpoints the advanced state to prevent replayed rewards, and shows a concise return report covering quests, kills, levels, deaths, gold, materials and gear. Debug builds can simulate ten minutes away instantly. A temporary 7-day technical catch-up cap prevents pathological prototype stalls; it is not a monetisation/retention rule and should be revisited when the offline simulator is optimised.

**Hard gate:** do not expand content until offline progression is trustworthy.

---

## IRPG-P3 — Equipment and inventory loop

**Status:** `VERIFY` — PR #5 completes the first equipment loop: eight restrained slots, inspect/comparison UX, equip/unequip, duplicate-safe sell for gold, duplicate-safe salvage for the existing gacha currency, Gear-banner integration, persistence, guaranteed world gear, visible weapon variants and modular armour visuals. Android usability/visual validation remains.  
**Goal:** create the first meaningful management game.

Build:
- core equipment slots;
- item comparison;
- equip/unequip;
- inventory;
- sell/salvage;
- visible weapon changes;
- rarity/affix foundation;
- world drops feed the same inventory as gacha gear.

Acceptance:
- returning with loot regularly creates a real equip/keep/salvage decision;
- stats remain readable;
- equipping changes combat outcomes;
- at least weapons visibly change in 3D;
- gacha gear does not invalidate ordinary drops.

---

**Implementation note:** itemisation is still intentionally simple. P3 proves the management loop; it does not introduce random affix soup, crafting/upgrading, durability or extra currencies. Those require a later design need.

---

## IRPG-P4 — Talents and build identity

**Status:** `VERIFY` — PR #6 implements the first Wayfarer build system: 12 talents across Slayer, Warden and Trailblazer, one point per level after level 1, prerequisite chains, free prototype respec, persistent automatic effects and a portrait-friendly branch drawer. Android readability/build-feel validation remains.  
**Goal:** let the player meaningfully coach automatic combat.

Build:
- first class tree;
- automatic ability triggers;
- respec;
- build summary;
- event hooks for talent effects.

Acceptance:
- at least three recognisably different builds are viable;
- watching combat makes those builds look different;
- no build requires active combat input;
- nodes are meaningful rather than filler percentages.

**Implementation (PR #6):**
- **Slayer:** Heavy hand, Sharpened edge, Executioner, Bloodlust.
- **Warden:** Thick hide, Iron guard, Second wind, Last stand.
- **Trailblazer:** Quick hands, Trail legs, Opening strike, Hunter's eye.
- Talent state is authoritative and persists through save/offline simulation.
- Talent procs emit events and receive restrained branch-specific watch-mode cues: Slayer, Warden and Trailblazer are visually distinguishable without turning combat into a particle storm.
- Unspent talent points are surfaced on the main action row.
- Level-ups earned while offline report newly available talent points and offer a direct action into the talent drawer.
- No active combat buttons were added.
- Respec is free during prototyping so build experimentation is cheap.

---

## IRPG-P5 — Gacha collection layer

**Goal:** turn the prototype gacha into a real long-term collection system.

Build:
- polished summon reveal;
- banner history;
- visible pity;
- duplicate conversion;
- Gear / Companion / Relic collection pages;
- “new” and favourites/lock;
- expanded dev tools;
- initial economy earning sources.

Acceptance:
- lots of pulls are fun even with infinite dev currency;
- duplicates retain some value;
- collection management remains usable on phone;
- the system has one understandable gacha currency;
- no monetisation requirement is needed to make the loop work.

---

## IRPG-P6 — Companion system

**Goal:** give the adventurer a collectible visible partner.

Build:
- one active companion slot;
- companions follow in world;
- simple roles/passives;
- companion progression;
- companion gacha integration.

Acceptance:
- companions visibly change the watched experience;
- choice changes simulation outcomes;
- system does not become a second full character-management spreadsheet.

---

## IRPG-P7 — World expansion

**Goal:** turn the vertical slice into a small RPG journey.

Build only after P1–P6 are stable:
- several zones;
- town variety;
- quest chains;
- named bosses;
- zone progression;
- travel transitions;
- light narrative.

Guardrail:
Each new zone must introduce at least one meaningful gameplay or spectacle change. Do not clone the same kill quest ten times with different nouns.

---

## IRPG-P8 — First profession + minigame

**Goal:** prove optional active play without manual combat.

Recommended first candidate: fishing.

Build:
- passive profession progress;
- optional tactile minigame;
- profession collection/rewards;
- useful but non-mandatory interaction rewards.

Acceptance:
- ignoring the minigame does not brick progression;
- playing it feels worthwhile;
- it works comfortably one-handed on phone.

---

## IRPG-P9 — Dungeons and simulated parties

**Goal:** deliver the MMO fantasy without networking.

Build:
- dungeon task;
- simulated party roles;
- encounter sequence;
- boss;
- dungeon loot table;
- party summary;
- visible party members when watched.

Acceptance:
- preparation/build matters;
- failure is understandable;
- party behaviour is legible;
- offline and watched dungeon results share the same authority.

---

## IRPG-P10 — Guild and social simulation

**Goal:** create the feeling of belonging to an MMO community.

Possible scope:
- simulated guild roster;
- NPC guildmates with roles/progression;
- guild objectives;
- asynchronous-feeling activity feed;
- party invitations/events generated by simulation.

Do not imply these are real human players.

No networking required.

---

## IRPG-P11 — Raids and endgame

**Goal:** provide long-term aspirational content.

Build:
- raid preparation;
- multi-boss run;
- build checks;
- raid loot;
- long-term progression;
- repeatable endgame goals.

Only begin when dungeon simulation is proven.

---

## IRPG-P12 — Content scale and polish

Build:
- additional class(es);
- broader item pools;
- companion variety;
- more professions;
- zone polish;
- animation/audio pass;
- performance improvements;
- accessibility;
- save hardening;
- Android release QA.

Do not confuse content volume with finished quality.

---

# 24. Immediate next actions

Do these in order:

1. Keep PR #5 and dependent PR #6 green in Godot 4.7.2 CI.
2. Phone-test P3 equipment and P4 talents together: drawer readability, touch targets, visible gear, talent spending/respec and whether Slayer/Warden/Trailblazer actually feel different while watching.
3. Fix mobile/core-loop blockers only.
4. Merge P3 before P4, then retarget/verify P4 against updated main.
5. Do not begin P5 collection polish until the management loop is pleasant on the phone.

Do not respond to a mediocre phone test by piling on more zones, classes, currencies or content. Fix the little-adventurer loop first.

---

# 25. Decision log

## Locked for now

- Godot 4.7.2.
- Android portrait is primary.
- Low-poly 3D world.
- One persistent adventurer first.
- Watchable autonomous play.
- No manual combat.
- Management through gear/talents/collection.
- Optional active minigames.
- MMO-like structure without requiring real multiplayer.
- Gacha is a major progression/collection pillar.
- Debug builds have effectively unlimited gacha resources.
- Simulation is authoritative; 3D presentation never creates separate outcomes.
- Offline progression is core, not an afterthought.

## Deliberately unresolved

Do not prematurely lock:
- final class roster;
- final setting/title;
- exact gacha rates;
- monetisation;
- final pity model;
- exact offline cap;
- final death penalty;
- exact stat formula;
- final profession list;
- real online/social features;
- final art asset pipeline.

Resolve these with prototypes and evidence, not because a roadmap needs every blank filled.

---

# 26. The test for every future feature

Before adding a feature, ask:

1. Does this make me care more about my adventurer?
2. Does this improve the idle/management decision loop?
3. Does this make the world more satisfying to watch?
4. Does this create a meaningful build/collection decision?
5. Can it work while the app is closed?
6. Is it worth the added complexity on a phone?

If the answer is “no” to almost all of those, it probably does not belong in this game.
