# Three reference pillars and token sales — Idle RPG

**Owner decision, 9 October 2026:** The three enduring design references are **Slayer Legend**, **Idle Slayer**, and **World of Warcraft**. **Selling gacha tokens is a core commercial objective** for this game, not merely an optional afterthought. These statements guide balancing, content priorities, gacha systems, retention and eventual monetisation.

This is *inspiration*, not a licence to clone any game's copyrighted characters, art, UI or progression tables. Our identity remains one persistent, watchable 3D adventurer whose battles resolve autonomously and whose player manages growth, builds, equipment and activities.

## The three pillars

| Reference | Primary role | What we adapt |
|---|---|---|
| **Slayer Legend** | Rewarding idle power growth **and a compelling summon economy** | Frequent character progress, item and skill upgrades, meaningful duplicate use, aspirational rarities, evolving character development, purchases that add exciting optional summons/collection opportunities. |
| **Idle Slayer** | Layered, unfolding **long-term progression** | Small early goals that develop into more quests, unlocks, systems, areas, collections, crafting and milestones. Optional later reset-like mechanisms only if they fit persistent-character attachment. |
| **World of Warcraft** | **RPG identity, specialisation and world** | Coherent zones, quests, gear, class/build tradeoffs, professions, boss preparation and counters, dungeons, guilds and cooperative raids. An adventurer, not just an upgrade spreadsheet. |

**Product shorthand:** *Slayer Legend's rewarding growth and gacha excitement + Idle Slayer's long progression arc + WoW's RPG depth and persistent world — presented as an autonomous 3D character.*

**Visual hierarchy (owner decision, 9 October 2026):** **World of Warcraft is also the primary visual inspiration**, not simply a gameplay pillar. Use original WoW-like painterly stylisation, expressive heroic proportions, legible colourful worlds, exaggerated gear and iconic enemy silhouettes, made with **low-poly, Android-friendly assets**. RuneScape is a secondary efficiency/readability reference; Kingdoms of Amalur is secondary shape inspiration. A fully voxel art direction is not currently selected. See [ART_STYLE_GUIDE.md](ART_STYLE_GUIDE.md); do not copy Blizzard's identifiable art or UI.

**9 October 2026 gacha research guardrails:** Published low base top-tier rates in successful games are *not* proof that the same exact odds maximise our revenue or enjoyment. Prototype 1%/80, 1.5%/80 and 2%/60, with separate persistent target-spark and guaranteed pulls; measure actual reward frequency, free gifts, paid/free collection curves and complete-account saturation. Special-event chest progress must count free and purchased sources equally; the proposed 50-free/50-mandatory-paid 100-chest 'guarantee' cannot be represented as a generally earnable reward. See [GACHA_ODDS_AND_PROMOTIONS.md](GACHA_ODDS_AND_PROMOTIONS.md).

## Commercial priority: players should want to buy gacha tokens

The owner explicitly wants revenue from **gacha-token purchases**. Do not quietly downgrade monetisation to cosmetics-only, or model the economy as though tokens are merely an unlimited free toy.

- Make **free pulls satisfying and reasonably frequent** so gacha is an enjoyable part of ordinary gameplay. Paid token bundles should add real optional collection breadth, pulls, customisation and build experimentation; their value needs to be understandable.
- Provide **desirable, distinctive things to chase for months** across gear, companions, relics and cosmetic summon families; avoid instant catalogue saturation. Rarity alone is not a substitute for an interesting item with an actual purpose.
- Make **duplicates valuable** via bounded upgrade, material/conversion, collection or targeted-progress uses rather than only near-worthless refunds. Avoid infinite power feedback loops or guaranteed spend-to-win competitive outcomes.
- Do not balance as an *infinite-token development sandbox*. Keep developer token tools isolated from normal releases and trusted multiplayer, and test normal free, light-spending and heavy-spending paths **separately**.
- Honour prior commitments to **published odds, pity/protection, purchasable-item clarity, honest offers, purchase restoration and secure server-owned currency** before taking real money. Purchased tokens must not be lost by save migrations, server retries or other routine operations. Billing requires verification before public sales.
- Spending should accelerate *desirable optional progression* and diversify collections, without making the free player miserable or selling uncapped dominance in normalized ranked PvP. Bounded paid advantages in non-normalized progression content require explicit balance measurement rather than wishful assumptions.
- Pricing, rates, bundle design, free-vs-paid income and conversion should be measured and playtested, **not made up as fixed numbers**. Support good revenue without bait-and-switch odds, coercive timers, fake scarcity, forced logins or mandatory purchases.

## Pace and long-term satisfaction

**The owner's 9 October Android report: all builds maxed and full legendary equipment after approximately 15 minutes.** This is a fundamental progression failure. Investigate whether developer/unlimited gacha tokens were active before changing normal legendary probabilities, and independently correct the indisputable lack of meaningful build limits, weak difficulty and rapid experience/level scaling. See [P0 issue #45](https://github.com/gabebartolo-spec/Idlerpg/issues/45).

- First 5–15 minutes: character is visibly developing; choose a direction, earn upgrades and see an aspirational next goal. **Not:** unlock every talent, beat every challenge or exhaust the top-tier collection.
- First hour/day: meaningful choices and challenge; upgrades and summons still worthwhile; new activity layers appear gradually.
- First week: multiple viable build paths, distinctive dungeon/boss and gear ambitions, actual reasons to return.
- Weeks/months: further world/character mastery, gear targets, diverse collections, social/team pursuits and genuinely new goals instead of just waiting on longer timers.

Avoid solving a short game merely by multiplying XP costs or loot timers. Player agency must be expressed in **preparation, builds and management**, not twitch combat, mandatory tapping or input-heavy minigames.

## Execution and proof

1. **Fix P0 first-session saturation** in [issue #45](https://github.com/gabebartolo-spec/Idlerpg/issues/45). Reproduce both non-debug and debug token conditions before touching drops.
2. **Economy validation (R01, R10, R11, R43):** compare new-account outcomes at 15 min, 1 hour, 1, 7, 30, 90 and 180 days; separately examine free/light/high-spend cohorts, meaningful upgrade rates, catalogue saturation, progression speed, and actual desirability of paid pulls.
3. **Commercial prototype (R22, R23, R25):** design purchase bundles and summons that players *voluntarily* find worthwhile; mock purchase experiences before real verified Android billing, entitlements, accounting and restoration.
4. **Actual phone playtests:** acceptance depends on player experience, not only a mathematically deterministic automated simulation.

Related: [DESIGN_BIBLE.md](DESIGN_BIBLE.md), [RESEARCH_BACKLOG.md](RESEARCH_BACKLOG.md), [ECONOMY_BASELINE.md](ECONOMY_BASELINE.md), [PLAYTEST_TARGET.md](PLAYTEST_TARGET.md).
