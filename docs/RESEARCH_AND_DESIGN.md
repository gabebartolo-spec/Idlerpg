# Research and Design

**Status:** Design proposal; awaiting approval before implementation  
**Research snapshot:** 2026-09-25 UTC  
**Primary hypothesis:** The emotional reward of an authored, understandable return report plus a meaningful gear/route decision can make a very small offline RPG compelling without real-time combat, multiplayer, or monetisation.

## 1. The central design problem

This project is not primarily about simulating an MMORPG. It is about making the player care about a single persistent character during the time the player is absent.

The loop to prove is:

1. Make a small amount of preparation.
2. Choose what the adventurer will pursue.
3. Leave.
4. Return with uncertainty and a legible account of what happened.
5. Find something worth inspecting.
6. Make a decision that changes the next expedition.
7. Feel curious about the next report.

The important unit is therefore not “hours of offline income.” It is **one departure-to-return story**.

## 2. Research findings

The sources below are examples and evidence, not templates to copy. “Observed” means the source describes a mechanic or player response. “Inference” is a design conclusion for this project.

### Idle and incremental games

- **Melvor Idle** explicitly calculates offline time on return rather than simulating every moment while the app is closed. Its return summary can grant skill XP, mastery XP, items, and other rewards; its documented offline progression is capped and combat has explicit safety rules. [Melvor Idle: Offline Progression](https://wiki.melvoridle.com/w/Offline_Progression)
  - **Observed:** a player can leave one selected action running, then receive a contextual summary on return.
  - **Inference:** elapsed-time resolution is both feasible and more honest to the fantasy than maintaining a fake live simulation. A report must explain the result, not merely award a currency total.

- The GDC talk **Quest for Progress** describes idle games as games in which progress happens without interaction while player choices affect growth, and discusses visible power growth, optimal decisions, and the pacing of reset cycles. It also records a designer criticism of a short offline limit in *Egg, Inc.* as a reason that particular loop lost its appeal for that speaker. [GDC presentation](https://media.gdcvault.com/gdceurope2016/presentations/Pecorella_Anthony_Quest%20for%20Progress.pdf)
  - **Observed:** leaving the game is part of the expected play pattern; the return must lead to another useful decision.
  - **Inference:** offline time should not be a monetisation gate or a punishment. If a cap is later needed for balance, it must be a transparent simulation rule rather than an appointment mechanic.

- The CHI paper **“It Started as a Joke”: On the Design of Idle Games** describes the genre as handing control back and forth between player and system. It also identifies the need to support cognitive offloading, communicate waiting periods, and avoid making the player return to reconstruct an opaque plan. [CHI Play paper](https://www.researchgate.net/publication/336711769_It_Started_as_a_Joke_On_the_Design_of_Idle_Games)
  - **Observed:** waiting is not an interruption to the loop; it is part of the loop, but it creates memory and interpretation costs.
  - **Inference:** the camp screen must remember the player’s plan, and the return report must summarize causality in a few readable events.

- **Progress Quest** is a useful boundary case. Its official manual describes a “fire and forget” RPG with automatic combat, quests, leveling, and saving. It demonstrates how much RPG texture can be generated without input, but it is intentionally close to a zero-player parody. [Progress Quest manual](https://progressquest.com/info.php)
  - **Observed:** autonomous RPG simulation can be entertaining as spectacle.
  - **Inference:** this project must retain meaningful choices. If equipment never changes future outcomes or every route has the same answer, the result is a progress viewer rather than an RPG.

### Automated RPGs and return rewards

- **AFK Arena** presents automated battles and AFK rewards, then layers hero collection, team composition, equipment, factions, many modes, and monetised acceleration on top. Its store descriptions make the promise explicit: heroes fight while the player is logged off and rewards are collected on return. [App Store description](https://apps.apple.com/fm/app/afk-arena/id1375425432)
  - **Observed:** the “come back to collect progress” appointment is immediately understandable, and team composition gives active sessions a planning role.
  - **Inference:** the useful part to borrow is the clarity of the handoff between automation and management, not the collection, gacha, currency, or mode volume. Those systems would obscure the question this prototype needs to answer.

- **Melvor Idle** is a stronger structural reference than most AFK RPGs because its core is an individual character performing a selected action rather than a monetised roster. Public player feedback also shows the tradeoff: some players value the connected progression, while others report that the interface, slow grind, or amount of choice becomes overwhelming. These are anecdotal player reports, not controlled evidence. [App Store reviews](https://apps.apple.com/us/app/melvor-idle/id1518963622) · [community discussion](https://www.reddit.com/r/incremental_games/comments/1gdn923/melvor_idle_something_im_missing_why_do_people_love_it/)
  - **Inference:** depth should come from a few interacting decisions, not from exposing every possible RPG subsystem at once.

### Expeditions, risk, and persistent characters

- **Fallout Shelter** sends named dwellers into the wasteland with equipment and supplies. Exploration can produce weapons, outfits, caps, experience, logs, and danger; quests add more structured objectives. The official store description emphasizes returning with survival loot and the possibility of mission failure. [App Store description](https://apps.apple.com/us/app/fallout-shelter/id991153141)
  - **Observed:** preparation, a named character, risk, a log, and recovered loot make an absence feel like an expedition rather than passive income.
  - **Inference:** this is the closest emotional precedent for the proposed loop. The prototype should test a compact version of that sequence without adopting its vault-management layer or long multi-day excursions.

- **Darkest Dungeon** makes persistent characters emotionally legible through expedition consequences, stress, treatment, and a graveyard. Its design shows that risk can create attachment, but also that permanent loss and recovery systems can dominate the experience. [Heroes and expedition reference](https://darkestdungeon.wiki.gg/wiki/Heroes_(Darkest_Dungeon))
  - **Observed:** consequences matter more when the player can remember who suffered them and sees the character again in the hub.
  - **Inference:** the first prototype should use recoverable defeat/retreat, not permadeath. We need to test anticipation and attachment before testing grief, loss aversion, or campaign recovery.

- **XCOM 2: War of the Chosen** uses persistent soldiers, customization, missions, wounds, and bonds. Bonds are an example of attachment emerging from repeated shared history rather than from a large amount of lore. [Steam description](https://store.steampowered.com/app/593380/XCOM_2_War_of_the_Chosen/)
  - **Inference:** even one adventurer can gain attachment from a name, remembered discoveries, near misses, and a growing expedition log. A roster is not required to test character attachment.

### MMORPG progression and loot

- **World of Warcraft** established a highly legible progression grammar: quests and enemies provide experience, levels unlock capabilities, and challenges provide equipment and money. Rested experience also turns time away into a positive progression state. [Progression overview](https://wowpedia.fandom.com/wiki/Leveling) · [rested experience reference](https://warcraft.wiki.gg/wiki/Rest)
  - **Observed:** the combination of objectives, increasing capability, and rewards gives the player a reason to move through a world.
  - **Inference:** the prototype needs only the grammar—objective, fight, XP, level, gold, item, next objective—not the world scale, classes, group roles, or social systems that support the full MMO.

- ARPG loot systems show why rarity alone is insufficient. In its *Loot Reborn* itemisation update, Blizzard said it reduced affix counts and made upgrades easier to understand, while moving some complexity into separate systems. [Blizzard itemisation update](https://news.blizzard.com/en-us/diablo4/24077223/galvanize-your-legend-in-season-4-loot-reborn)
  - **Observed:** even a large loot-driven game treated item readability and reduced clutter as explicit design goals.
  - **Inference:** the prototype should use a small set of authored sidegrades. Rarity may signal discovery, but the equip decision must be readable in one glance and depend on the chosen route.

## 3. Why the return moment can work

The return screen is the product’s main emotional surface. It should do five things in order:

1. **Orient:** “You were away for 2 hours 14 minutes. The adventurer went to the Gloamroot Cavern.”
2. **Headline:** show the one most memorable outcome first: a rare find, level-up, close escape, or defeat.
3. **Reconstruct:** show a short, grouped event log—travel, important fights, discoveries, and outcome—not every combat tick.
4. **Convert surprise into agency:** present new items with comparisons and a clear equip/sell decision.
5. **Create the next question:** show the available routes and why their risk/reward profiles differ.

The player should be able to answer these questions without opening a submenu:

- What did my adventurer do?
- Did the plan work?
- What changed on the character?
- What is the most interesting new thing?
- What should I do next, and why?

A report that only says “+4,200 gold” is an accounting statement. A report that says “Sable reached the watchtower, barely survived a thornback ambush, and brought home a charm that makes rare finds more likely” is a small character story. The latter is the target.

### Return-moment rules for the prototype

- Generate a **headline** from real simulation results, never from a fake reveal animation.
- Show no more than 5–7 grouped events in the default report.
- Guarantee that a successful test expedition produces at least one inspectable change—XP, gold, or an item—while keeping rare items genuinely uncommon.
- Make close calls and failure visible, but preserve enough progress that a player has a reason to send the adventurer again.
- Keep the report actionable in roughly 30–90 seconds.
- Preserve the last several meaningful events in a history screen so the adventurer develops continuity.

## 4. Why loot decisions become meaningful

“Equip the larger number” is not a build decision. The prototype needs opportunity cost without an affix spreadsheet.

Recommended constraints:

- Three equipment slots: **weapon, armor, trinket**.
- Three player-facing properties: **Strike** (combat pace), **Guard** (survival), and **Fortune** (quality/chance of finds and some gold outcomes).
- Three rarity tiers: **Common, Uncommon, Rare**. Rarity affects availability and presentation; it is not a universal replacement for comparison.
- Each item has one clear identity and at most two meaningful bonuses. A lower-Strike item can be desirable because it has Fortune; a high-Guard item can be preferable on a risky route.
- Route cards expose different priorities: a safe gold route, a balanced discovery route, and a dangerous rare-loot route.
- The comparison view must show deltas against equipped gear and a short route-impact explanation. Do not display one composite “best item” score.
- Use a small authored loot table, approximately 8–10 items, so the player can remember names and recognise a discovery.
- Let the player equip or sell. **Salvage, crafting, rerolling, and procedural affix generation are deferred.**

The desired decision is not “which item has the biggest colour?” It is “I can survive the Thornwatch route with the reinforced coat, but the moonlit charm might be worth the risk if I am hunting the rare drop.” If testers cannot state why they equipped an item, the item system has failed even if the numbers are balanced.

## 5. Strongest opportunities

1. **A personal micro-story generator:** one named adventurer and a compact event history can create attachment with very little content.
2. **Anticipation through authored uncertainty:** the player knows the route profile but not the exact event sequence or item roll.
3. **High information density in short sessions:** one report can deliver narrative, progression, loot, and the next choice in under a minute.
4. **Depth from interaction rather than volume:** Strike, Guard, Fortune, three route profiles, and a few items can create real tradeoffs.
5. **Efficient cross-platform simulation:** resolving event boundaries from elapsed time makes mobile suspension, desktop closing, and automated testing simple.
6. **A clean commercial foundation:** proving the unpaid loop first avoids confusing retention with monetisation pressure.

## 6. Biggest risks and mitigations

| Risk | Why it matters | First mitigation |
|---|---|---|
| The game is only a progress viewer | If player choices do not change future outcomes, there is no game to return to | Route profiles and sidegrade gear must affect combat, risk, and loot outcomes |
| Reports feel like spreadsheets | Aggregate numbers do not create attachment | Headline, named adventurer, grouped events, one standout discovery |
| Loot is clutter | Frequent junk makes the return screen a chore | Low drop volume, small authored pool, three slots, one-glance comparison |
| One route or build is obviously optimal | Choices become ceremony | Tune routes to reward different stat profiles; test selection distribution and player explanations |
| Failure feels unfair or ends the experiment | Permanent loss can overwhelm the core question | Recoverable retreat, partial progress, no permadeath in the first prototype |
| Idle time becomes a chore or appointment | Caps and timers can turn absence into pressure | No monetisation gates; prototype uses short expeditions and developer time controls |
| Complexity arrives too early | MMORPG feature parity is not depth | Strict scope budget and explicit non-goals below |
| Offline results are unreliable | Lost or duplicated rewards destroy trust | Pure deterministic simulation, injected clock, seeded randomness, atomic versioned saves |
| The character has no identity | A generic avatar cannot carry a return story | Name, placeholder portrait, route/event history, memorable item names |

## 7. Failure cases worth studying

These are not claims that a whole game is unsuccessful; they are public examples of failure modes to avoid.

- Progress Quest’s intentionally minimal interactivity is a useful warning: autonomous activity without consequential choices can read as a joke or screensaver rather than an RPG. [Official manual](https://progressquest.com/info.php)
- Public reviews and discussions of Melvor Idle praise connected progression and offline play but also repeatedly mention UI complexity, long grinds, decision paralysis, and late-game clutter. This is anecdotal and audience-specific, but it aligns with the design risk of exposing too many systems too early. [App Store reviews](https://apps.apple.com/us/app/melvor-idle/id1518963622) · [community discussion](https://www.reddit.com/r/incremental_games/comments/1gdn923/melvor_idle_something_im_missing_why_do_people_love_it/)
- A review of Fallout Shelter describes its charm but also periods of simply waiting for resources, illustrating how a strong setting and expedition hook can still be surrounded by downtime that lacks a meaningful decision. [Review example](https://jinxthegamecritic.wordpress.com/reviews/fallout-shelter/)
- Public complaints around monetised AFK RPGs often focus on repetitive progression, overloaded screens, and pressure to return or pay. These reports are not a substitute for product research; they reinforce the decision to test this concept with no ads, purchases, energy, gacha, or artificial urgency. [Example discussion](https://www.reddit.com/r/AndroidGaming/comments/zd43ag/whats_the_freaking_poit_of_idle_rpg/)

## 8. Design principles

1. **The adventurer is the product, not the economy.** Every system must make the character’s journey more legible, surprising, or consequential.
2. **Return first.** If a feature does not improve anticipation before departure or interpretation after return, it is suspect.
3. **Small choices, real consequences.** A few route and gear choices are better than many automatic upgrades.
4. **Readable uncertainty.** Tell the player what type of risk they are taking without revealing the exact result.
5. **No number without a reason.** XP, gold, and stats need a visible consequence or they are candidates for removal.
6. **Respect absence.** Offline progress should work because the player left, not because the game is trying to punish or sell the player for leaving.
7. **Recoverable experiments.** The prototype should let players try a build, understand the result, and try another route without losing a campaign.
8. **Depth before breadth.** Do not add classes, zones, professions, parties, or endgame until one adventurer is worth checking on.
9. **Evidence over genre assumptions.** Treat every claim about retention, session length, loot frequency, and offline duration as a testable hypothesis.
