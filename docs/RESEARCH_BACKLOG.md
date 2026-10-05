# IdleRPG research-backed build backlog

Updated 5 October 2026. Evidence and commercial comparisons: [MOBILE_GENRE_RESEARCH.md](MOBILE_GENRE_RESEARCH.md). Product rules and phase verification: [DESIGN_BIBLE.md](DESIGN_BIBLE.md). All **IRPG-R00–R35** items below are proposed and unstarted; documentation does not mark gameplay as complete.

## Product agreement

One persistent, autonomous adventurer remains the emotional center. Real guilds, PvP, cooperative raids, global bosses and guild wars are now a committed product direction, superseding NPC-only social plans. Start asynchronously so players can contribute while the app is closed. F2P/light spenders get useful roles, attainable builds and generous collection progress. Larger spenders get collection depth, visible prestige and bounded progression advantages. Normalized ranked competition has no paid power advantage; progression competition explicitly permits differences and must control them. No paid war points, forced attendance, destructive looting or purchased protection.

These are hypotheses to validate, not a directive to copy every successful game's features. Do not add five concurrent multiplayer queues to a small population. Priority A means foundations/next slices, B means validated expansion, C means population/commerce-dependent. S/M/L/XL are relative scope, not delivery estimates. Dependencies are mandatory; priority alone never overrides them.

## Queue and dependencies

| ID | Build | Priority / size | Depends on |
|---|---|---|---|
| R00 | Current Android verification and blockers | A / M | Current P0–P7 implementation |
| R01 | Economy and enjoyment baseline | A / M | R00 |
| R02 | Save/offline resilience and efficiency | A / L | R00 |
| R03 | Adventurer chronicle and return highlights | A / M | R02 |
| R04 | Three-goal adventure board | A / M | R03 |
| R05 | Player-selected autonomous policies | A / M | R04 |
| R06 | Free named build loadouts | A / M | R02 |
| R07 | Equipable relics with useful effects | A / M | R06 |
| R08 | Boss counters and defeat explanations | A / M | R05, R07 |
| R09 | World item effects and target farming | B / L | R08 |
| R10 | Duplicate protection and selected-item path | A / M | R01, R02 |
| R11 | Generous earned-draw economy | A / M | R01, R10 |
| R12 | Discoveries and permanent collection journal | B / M | R03, R09 |
| R13 | Adventurer identity and visible keepsakes | B / M | R03 |
| R14 | Companion role balance and bond moments | B / M | R08 |
| R15 | Fishing profession and optional minigame (P8) | B / L | R05, R11 |
| R16 | One practice dungeon and party roles (P9) | B / L | R08, R14 |
| R17 | One short expedition with route choices | B / L | R05, R09 |
| R18 | Real guild membership and shared project (P10) | B / L | R13, R28, R29, R30 |
| R19 | Rotating contracts without attendance pressure | B / M | R04, R11, R35 |
| R20 | Two-boss endgame raid chapter (P11) | C / L | R09, R31 |
| R21 | Cosmetic wardrobe and social previews | B / M | R13 |
| R22 | Mock store and price/value tests | B / M | R01, R11, R21 |
| R23 | Paid collection bundles and boost bounds | C / M | R10, R11, R22, R29 |
| R24 | Permanent adventure pass | C / L | R19, R22 |
| R25 | Verified Android billing and entitlements | C / XL | R22, R29, R35 |
| R26 | Enjoyment, fairness and commerce telemetry | A / M | R01 |
| R27 | Audio, accessibility and Android performance | B / L | R00, R03 |
| R28 | Online architecture/account prototype | A / L | R02 |
| R29 | Server-owned progression and economy | A / XL | R01, R28 |
| R30 | Friends, profiles and safe social interaction | B / L | R13, R28 |
| R31 | Three-player asynchronous cooperative raid | B / XL | R16, R18, R29 |
| R32 | Community global boss | C / L | R31, R35 |
| R33 | Snapshot PvP: normalized then progression | C / XL | R08, R29, R30, R35 |
| R34 | Asynchronous guild war pilot | C / XL | R18, R31, R33, R35 |
| R35 | Live event operations and reward audit tools | B / L | R26, R29 |

## Claude execution contract

Read the bible, this backlog, research and applicable repository instructions. Pick **one** ready ticket; inspect current code before choosing files. Suggested paths below are starting points, not mandates. Preserve simulation/presentation separation, autonomous combat, portrait usability and save compatibility. New data catalogs should be small and deterministic. Do not expand `src/main.gd` with another monolithic subsystem when a focused module fits.

For each ticket: implement the smallest playable slice; document its rules; add meaningful tests for changed simulation, persistence, network or economy behavior; run required CI checks and `git diff --check`; describe remaining Android/device checks honestly. Changes affecting watches/offline outcomes need parity checks. Server tickets need multi-client integration, concurrency/retry tests and a local runnable environment. Mocks are useful but do not prove real multiplayer. Never provision paid infrastructure or enable live purchases just to close a prototype ticket.

Definition of done: acceptance below demonstrated, no free-player regression, documented save/API migration where needed, appropriate tests passing, and a reviewable PR. Phone-dependent phases remain VERIFY until actual device evidence exists. Add an implementation/verification note here rather than silently changing the meaning of DONE.

Copyable prompt: “Implement IRPG-RXX from docs/RESEARCH_BACKLOG.md. Read docs/DESIGN_BIBLE.md and docs/MOBILE_GENRE_RESEARCH.md first. Verify dependencies against the current checkout. Complete only this ticket's playable slice and acceptance criteria, run appropriate checks, and open a PR explaining player benefit, validation and remaining device checks. If a dependency is missing, identify it and implement no dependent shortcut.”

Recommended first sequence: R00 → R01 → R02 → R03 → R04. R06/R10 can follow; R28 begins the online foundation after R02. R26 instrumentation supports subsequent playtests. R29 precedes all trusted online progression. After R16/R18, ship **one real cooperative raid** before world bosses, PvP or wars. The eventual multiplayer order is guild project → raid → global boss → arena → wars.

## Ticket cards

### IRPG-R00 — Verify the existing game on Android

**Payoff:** make the existing two-zone adventurer pleasant before multiplying systems. **Scope:** test current main's equipment, talents, collection, companion, Briarfen boss, offline report, suspend/resume and touch layout; record device/OS/build SHA and fix blockers. **Start:** `src/main.gd`, `src/sim/adventurer_sim.gd`, device checklist in bible. **Accept:** readable portrait UI, reliable resume, understandable second-zone progression and no touch-blocking overlays; attach actual observations. **Validate:** current CI plus real phone session. Headless green alone does not close this gate. **Exclude:** new zone or monetization.

### IRPG-R01 — Establish economy and fun baselines

**Payoff:** avoid tuning progression by intuition. **Scope:** reproducible seeded 1/7/30-day simulation reports for F2P, light and collector scenarios; track currency sources/sinks, useful upgrades, boss failures, pity/selected-item completion and time at a wall. Include average and unlucky sequences. **Start:** `src/game.gd`, simulation/catalogs, new economy report tool. **Accept:** checked-in baseline inputs/results, no impossible negative balances, sensitivity to proposed rates and documented player-facing goals. **Validate:** reproducibility plus 8–12 formative seven-day playtests when recruitable; record unmet research separately. **Exclude:** changing all rates or treating small samples as statistical proof.

### IRPG-R02 — Harden saves and offline catch-up

**Payoff:** trustworthy returns without a long frozen screen. **Scope:** versioned migration, atomic save/backup recovery, saved random state, explicit failure handling and more efficient catch-up preserving outcomes. Inspect current 0.1-second stepping at seven-day cap before optimizing. **Start:** `src/state/persistence.gd`, `src/game.gd`, `src/sim/adventurer_sim.gd`. **Accept:** existing version-1 save loads; corrupted/truncated saves recover visibly; repeated reload cannot replay rewards; clock rollback is handled; seven-day catch-up meets a measured device budget. **Validate:** seeded watched/offline parity, interruption, migration and duplicate-reward tests. **Exclude:** trusting these saves as online competitive state.

### IRPG-R03 — Chronicle and return highlights

**Payoff:** remember an adventurer's life rather than skim counters. **Scope:** persistent bounded events with stable IDs: first kill, first boss victory, useful gear, close defeat and companion bond. Return report selects three meaningful highlights and links to relevant management. **Start:** sim events, persistence, report UI. **Accept:** highlights survive reload, never fabricate events or repeat NEW rewards, and preserve aggregate totals; present no more than one report overlay. **Validate:** long catch-up, no-event return and phone readability. **Exclude:** generated dialogue service or endless logs.

### IRPG-R04 — Three-goal adventure board

**Payoff:** know what to work toward. **Scope:** three visible goals: immediate build improvement, next boss and long collection pursuit. Offer one player-selected tracked goal with honest requirement/progress and relevant navigation. **Start:** new goal catalog/controller, existing sim/UI. **Accept:** goals derive from real state, completed rewards grant once, unattainable goals offer a route, and offline completion appears in R03. **Validate:** new/returning/endgame accounts and reload. **Exclude:** mandatory daily checklist, extra currency or streak.

### IRPG-R05 — Autonomous adventure policies

**Payoff:** meaningful management while the hero acts independently. **Scope:** choose safe farming, push progression or targeted hunt; rules control existing activity selection and return thresholds. **Start:** sim decision logic, save schema, goals UI. **Accept:** each policy has a clear tradeoff, displayed destination/reason and consistent offline behavior; never locks the hero permanently into a death loop. **Validate:** same-seed policy comparisons and invalid-policy recovery. **Exclude:** manual combat commands or new pathfinding system.

### IRPG-R06 — Free named build loadouts

**Payoff:** experiment without repetitive swapping. **Scope:** three free named loadouts containing talents, equipment and active companion; preview missing pieces and apply atomically. **Start:** gear/talent/companion APIs, persistence, focused loadout UI. **Accept:** valid owned choices only, no duplication, no partial change on failure, safe fallback if an item was sold. **Validate:** respec, sale, reload and offline parity. **Exclude:** paid slots and infinite presets.

### IRPG-R07 — Make relic collection playable

**Payoff:** collected relics change a build. **Scope:** one relic slot and three readable effects drawn from the existing relic banner, with accessible free alternatives. **Start:** `src/game.gd`, new relic catalog, sim modifiers. **Accept:** owned relic selection saves; effect has measurable outcomes; one lower-rarity option wins a defined niche; unequipping removes the entire effect. **Validate:** stacking boundaries, parity and displayed-vs-applied stats. **Exclude:** multiple relic slots or a second upgrade currency.

### IRPG-R08 — Boss counters and useful loss explanations

**Payoff:** defeat teaches a next action. **Scope:** add one telegraphed boss mechanic and at least two free build counters; explain recent failure via actual battle events and suggest obtainable changes. **Start:** sim combat, enemy data, report/goal UI. **Accept:** a baseline free build can win with preparation under documented assumptions; suggestions never require a paid draw; counters remain autonomous. **Validate:** seeded counter/non-counter trials, unlucky F2P path and equal watched/offline outcomes. **Exclude:** reaction tapping or mandatory premium companion.

### IRPG-R09 — World item effects and target farming

**Payoff:** world loot retains value alongside gacha. **Scope:** three world-earned effects and two targeted drop goals in existing zones; define bounded bad-luck progress separate from purchasable collections. **Start:** gear catalog, loot/sim, policies. **Accept:** each item has a useful niche, drop/source information is accurate, selling/reacquiring cannot farm first-discovery rewards, and premium items do not strictly replace all world rewards. **Validate:** source/sink and long-run drop distributions. **Exclude:** affix explosion or new zone.

### IRPG-R10 — Duplicate protection and selected-item route

**Payoff:** a generous draw feels useful even late in a collection. **Scope:** publish duplicate conversion rules and a bounded route to one selected missing item, independent of random rarity pity. Prototype with existing tokens/fragments only if the economy needs them. **Start:** `src/game.gd`, collection UI, persistence. **Accept:** expected and maximum costs visible before drawing, pity/selection saves, capped collections have a useful outcome, duplicates cannot produce a profitable draw loop. **Validate:** worst luck, complete banner, restart and multi-pull boundary. **Exclude:** endless duplicate combat ranks.

### IRPG-R11 — Generous earned draws

**Payoff:** free and light-spending players see continual progress. **Scope:** test 100–150 tokens per ordinary simulated day (10–15 current-cost draws), with capped earning buckets independent of check-in frequency; maintain attainable world rewards. Numbers are tuning hypotheses. **Start:** rewards, R01 harness, return report. **Accept:** no quest-frequency exploit; comparable watched/offline income; free player can direct progress toward a useful item; document 1/7/30-day outcomes and unpaid boss viability. **Validate:** long catch-up, source/sink simulation and player diaries. **Exclude:** forced ads or attendance streaks.

### IRPG-R12 — Discovery and permanent journal

**Payoff:** long-term goals beyond bigger stats. **Scope:** one journal volume containing existing enemies, locations, world items and three small discoveries. **Start:** new discovery catalog, sim events, journal UI. **Accept:** discoveries are authored and reproducible, permanent entries never reset with events, rewards grant once and unearned entries show useful clues. **Validate:** migration, repeated kills and return highlights. **Exclude:** hundreds of collectibles or random-generated lore.

### IRPG-R13 — Identity and keepsakes

**Payoff:** care about this particular adventurer. **Scope:** name, a small appearance selection, two earned titles and first-boss keepsake; surface identity in report and watch view. **Start:** persistence, character presentation, identity UI. **Accept:** selection previews accurately, changes preserve progression, earned prestige differs visibly from paid appearance, future public names can be moderated. **Validate:** older saves, long names and phone silhouette. **Exclude:** copying another game's art or full character creator.

### IRPG-R14 — Companion roles and bond moments

**Payoff:** choose a companion for a reason. **Scope:** rebalance three existing companions into damage, protection and support niches; one bond vignette/visual cue per selected companion. **Start:** companion catalog, sim bond/modifiers, chronicle. **Accept:** at least one common/rare companion is useful in a specific encounter; no universal premium winner; bond growth works offline and moments trigger once. **Validate:** role comparisons, switch behavior and duplicate ownership. **Exclude:** roster combat or mandatory daily pet care.

### IRPG-R15 — Fishing slice / P8

**Payoff:** peaceful variety and useful preparation. **Scope:** one fishing spot, three catches, passive activity plus optional short minigame; catches prepare one dungeon consumable. **Start:** new profession catalog, sim activity, bounded minigame UI. **Accept:** passive-only players obtain all functional preparation; active play offers modest optional upside; stopping/reloading cannot duplicate catches. **Validate:** offline parity, interruption and real phone controls. **Exclude:** other professions or energy purchases.

### IRPG-R16 — Practice dungeon / P9

**Payoff:** learn cooperative build roles safely. **Scope:** three rooms, one boss and two explicitly labeled NPC practice allies; preparation and recap show tank/support/damage contributions. **Start:** focused encounter/party module, sim and presentation. **Accept:** one persistent hero retains identity, roles change success, rewards settle once, practice is available without human matchmaking. **Validate:** wipe/retry/reload, role trials and parity. **Exclude:** pretending NPCs are real people; this does not complete multiplayer.

### IRPG-R17 — Short route-choice expedition

**Payoff:** occasional adventure surprises with a real decision. **Scope:** one five-node expedition with two preselected routes, six authored encounters and a final reward; auto-resolve while away. **Start:** new expedition catalog/controller and policies. **Accept:** routes have legible risk/reward; selection saves; return tells a coherent sequence; free retries use time/preparation rather than paid rescue. **Validate:** deterministic replay, abort and reward settlement. **Exclude:** infinite procedural campaign or required live choices.

### IRPG-R18 — Real guilds and one project / P10

**Payoff:** progress belongs to a community. **Scope:** create/join/leave real guild, leader transfer, small capped roster and one shared project with personal participation rewards. **Start:** R28/R29 service modules and Godot guild UI. **Accept:** two separate accounts contribute to the same server state; roles/permissions enforced; membership changes cannot duplicate rewards; former members keep earned personal rewards; support contributions count. **Validate:** concurrent joins/leaves, leader inactivity, restart and sparse population. **Exclude:** NPC-only guild completion, guild trading or war.

### IRPG-R19 — Low-pressure rotating contracts

**Payoff:** varied goals without another chore list. **Scope:** one rotating contract family lasting several days, with banked catch-up progress and permanent core rewards available elsewhere. **Start:** goals/catalog, server event configuration for online grants. **Accept:** missed sessions do not lose owned rewards, late entrants have a usable path, no purchased milestone gate, visible server event bounds. **Validate:** timezone, expiration, delayed sync and authoring mistakes. **Exclude:** overlapping launch events or compulsive attendance rewards.

### IRPG-R20 — Endgame raid chapter / P11

**Payoff:** an aspirational shared victory. **Scope:** expand proven R31 to a two-boss chapter with contrasting counters, raid-specific world loot and a guild trophy. **Start:** encounter catalogs and raid service. **Accept:** free builds cover every necessary role; one paid damage build cannot bypass all mechanics; weekly-style reward limits are explicit and duplicate-safe; failure preserves useful progress. **Validate:** mixed spend cohorts and role compositions. **Exclude:** huge raid roster, uncapped stat escalation or synchronous attendance gate.

### IRPG-R21 — Cosmetic wardrobe and previews

**Payoff:** earned and purchased identity is visible. **Scope:** three cosmetics, one earned; portrait/world/profile preview, equip and ownership. **Start:** art pipeline, presentation, wardrobe catalog. **Accept:** cosmetics never change combat; preview matches purchased appearance; silhouettes/readability preserved; entitlement unavailable does not erase ordinary gear visuals. **Validate:** mobile cost, loadout interactions and reload. **Exclude:** large art inventory before desirability tests.

### IRPG-R22 — Mock shop and value research

**Payoff:** learn what players happily buy. **Scope:** clearly labeled no-charge prototype with starter keepsake, supporter offer, cosmetic suite and collector bundle at proposed localized-equivalent price anchors; disclose exact contents. **Start:** offer catalog and isolated shop UI. **Accept:** no real payment path or fake discounts/countdowns; player understands value before choosing; free path remains visible; collect preference/reasons rather than interpreting clicks as revenue. **Validate:** free/light/collector interviews and incomplete-collection edge cases. **Exclude:** real-money launch.

### IRPG-R23 — Bound paid collection and acceleration

**Payoff:** spending supports collection without erasing the game. **Scope:** model banner bundles and one non-stacking earning boost; start with a +25% specified-source test cap, then tune from evidence. **Start:** R01 harness, server economy catalog, mock shop. **Accept:** compare unpaid/light/high-spend 30-day useful progression; preserve world loot; publish caps and excluded competitive modes; buyers do not instantly exhaust all goals. **Validate:** boost expiry, offline accrual, refunded grants and normalized arena exclusion. **Exclude:** live purchases before R25 or paid war attempts.

### IRPG-R24 — Permanent adventure pass

**Payoff:** straightforward light-spender value without expiry anxiety. **Scope:** one finite track with free and premium rewards, buy-later retroactive eligibility and progress earned through normal adventures. **Start:** contract progress/entitlements, catalog/UI. **Accept:** purchased track never expires; no daily claim requirement; clear completion cost/time hypothesis; duplicate/reload grants settle once. **Validate:** buy-before/after completion, offline progress and refunded entitlement. **Exclude:** seasonal loss of a purchased track or pass-exclusive essential combat counter.

### IRPG-R25 — Android billing and purchase trust

**Payoff:** receive what was paid for reliably. **Scope:** test-track Google Play purchases; backend verifies purchase tokens, idempotently grants/acknowledges, restores ownership and processes refund/revocation notifications. Use current official billing guidance at implementation time. **Start:** Godot Android billing integration chosen in ADR, server entitlement ledger. **Accept:** pending payment grants nothing; retries/device changes cannot double-grant; valid paid ownership restores; support audit identifies an order without leaking credentials. **Validate:** license test purchases, pending/cancel/refund, network interruption and duplicate notifications. **Exclude:** production billing without release/operating readiness.

### IRPG-R26 — Measure enjoyment and fairness

**Payoff:** see whether features help people. **Scope:** versioned events for meaningful choice, report use, upgrade, boss result, earning, offer exposure and later social contribution; minimal anonymous local prototype export before remote analytics. **Start:** dedicated telemetry adapter, no secrets/client purchase authority. **Accept:** no raw chat/name collection; disable/export behavior documented; sampled events do not perturb simulation; cohort dashboards distinguish free/light/high spend with explicit definitions. **Validate:** event counts, schema changes and reconnect duplicates. **Exclude:** equating session length or spending alone with enjoyment.

### IRPG-R27 — Mobile delight and performance

**Payoff:** pleasant watching and usable management. **Scope:** small audio/animation feedback pass, independent sound controls, reduced motion, readable text, accessible contrasts and measured Android performance. **Start:** world/UI/audio modules. **Accept:** disabled effects do not change outcomes; target device frame/loading/memory budgets recorded; long return responsive; touch targets tested. **Validate:** sustained device play, suspend/resume and low-power scenario. **Exclude:** adding systems to mask weak presentation.

### IRPG-R28 — Online architecture and accounts

**Payoff:** recover an adventurer and connect safely. **Scope:** short architecture decision comparing suitable backend approaches, offline policy, hosting cost, account linking/recovery and deploy/rollback; runnable local account + authenticated profile prototype. **Start:** new `server/` and `src/services/` boundaries, chosen after inspection. **Accept:** separate clients share authenticated profile state; one cannot read/write another's private state; guest recovery/link conflicts handled; no credentials embedded. Explicitly decide legacy-save migration and compatible sim versioning. **Validate:** token expiry/reconnect, multi-device and local service setup. **Exclude:** provider lock-in without comparison or trusting uploaded local stats.

### IRPG-R29 — Server-owned online progression/economy

**Payoff:** protect multiplayer and purchase value. **Scope:** authoritative reward/inventory ledger, server clock, versioned deterministic encounter resolution and bounded offline accrual reconciliation. Debug/local sandbox state stays outside trusted rankings. Preserve legacy ownership through a documented fair migration rather than silently discarding it. **Start:** service economy/simulation modules and client sync. **Accept:** forged stats/time/reward claims rejected; two devices cannot spend the same balance; retry IDs grant once; interrupted offline sync has clear recovery; migration separates unverifiable legacy competitive power. **Validate:** concurrency, replay, tampering, rollback, reconciliation and ledger invariants. **Exclude:** client-authoritative PvP or purchased currency.

### IRPG-R30 — Profiles, friends and safe communication

**Payoff:** recognize guildmates and their builds. **Scope:** public profile with optional title/cosmetics, friend invite, inspectable role/loadout and structured guild messages. Include name validation, rate limits, block/report and a moderator review path. **Start:** profile/social services and dedicated client UI. **Accept:** block/report persists, private data inaccessible, abuse evidence minimal/access-controlled, muted users cannot bypass limits; actual human/NPC identities distinguishable. **Validate:** permissions, abusive names, duplicate invites and two-account blocking. **Exclude:** free-text/global chat until staffed moderation and escalation exist.

### IRPG-R31 — First real cooperative raid

**Payoff:** a free support adventurer can help friends win. **Scope:** three human players, one boss, proposed 24–48-hour preparation window, committed role/loadout and server-resolved automatic fight; replay/recap credits useful support. **Start:** R16 encounter module, guild/raid services. **Accept:** enrolled offline members participate; roster/build freezes prevent swapping exploits; disconnected/retried settlement grants once; no-shows handled predictably; free role mix viable. **Validate:** three-client run, late join, kick/leave, version mismatch and failure. **Exclude:** simulated humans, manual combat or paid revival.

### IRPG-R32 — Global boss pilot

**Payoff:** the whole community defeats something larger. **Scope:** one shared event ID, health fixed from pre-event population estimate, server-validated role contributions, personal milestones and community reward. **Start:** event/raid services and progress UI. **Accept:** contributions aggregate across accounts; last hit gives no exclusive essential reward; low population can progress; failed event still pays personal milestones; no timezone-exclusive attendance. **Validate:** concurrent lethal submissions, late arrival, outage recovery and sparse/high population simulations. **Exclude:** selling final-hit advantage or live spawn camping.

### IRPG-R33 — Two-rule-set snapshot PvP

**Payoff:** strategic rivalry and a place to show progression. **Scope:** first ship normalized arena using equal combat budgets and an accessible free ruleset roster; only then feature-flag separately labeled progression arena with power bands. Freeze server snapshots; resolve autonomous matches/replays. **Start:** authoritative encounter/matchmaking services and arena UI. **Accept:** paid boosts cannot enter normalized stats/choices; losses explain counters; progression power gaps and wait times measured; fixed free attempt budget; no hidden spend matching. **Validate:** mirrored fairness, snapshot tampering, smurfs, queue scarcity and spend-cohort win rates. **Exclude:** real-time controls, paid ranked retries or claiming power bands alone ensure fairness.

### IRPG-R34 — Guild war pilot

**Payoff:** a shared plan and visible team prestige. **Scope:** two opt-in small guild rosters, asynchronous preparation/combat window, three objectives including support/provision work, strength/activity/results matching and fixed free attempts. **Start:** guild/matchmaking/event services. **Accept:** developing characters affect an objective; roster locks prevent guild hopping; no purchase grants score/attempts; rewards recognize participation; no loss of owned personal gear. **Validate:** mismatched power/activity, sparse queue, absent members, collusion and duplicate settlements. **Exclude:** territorial destruction or massive cross-server wars.

### IRPG-R35 — Event operations and reward audits

**Payoff:** fair events survive mistakes and outages. **Scope:** versioned event configuration, server timers, dry-run validation, reward preview, scheduled enable/disable, audit history and a small operator compensation/reconciliation tool with permissions. **Start:** service admin tools; deployment/runbook docs. **Accept:** config cannot silently change active ranked rules; rollback/outage handling explicit; compensation idempotent; audit traces every competitive/paid grant; moderation escalation owner identified before public social launch. **Validate:** malformed configs, event boundary, rollback, duplicate compensation and unauthorized admin. **Exclude:** open client admin endpoints or five simultaneous live events.

## Playtest/release gates

Begin with observed sessions and seven-day diaries; later use cohorts large enough for the question. Record why players return, voluntary watching, meaningful choices, chore burden, attainable free counters and perceived purchase value. Set numerical launch thresholds only after baseline data; do not invent industry benchmarks.

Before each social mode, test at launch-like low population: can a newcomer find a guild/opponent, contribute while offline, understand a loss and earn useful progress? Before paid power, compare contribution and match outcomes across free/light/collector cohorts. Pause expansion if free players become spectators, guild membership feels compulsory, support roles go unrewarded, purchased progress exhausts goals, or match queues split the population. Before live billing, verify entitlement recovery, support/moderation capacity and actual cohort contribution after fees/refunds/hosting/content/acquisition costs.
