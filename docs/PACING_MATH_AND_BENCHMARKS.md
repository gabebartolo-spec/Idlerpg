# Idle RPG — Pacing mathematics, endless upgrades and benchmarking

**Owner decisions (9 October 2026):** Make progression seemingly **endless and constantly rewarding**. Every login should yield useful advancement. Provide frequent *minor* in-game upgrades with increasingly demanding *major* milestones, but **no progression dead zones**. Powerful early rewards must not unlock all talents and full legendary gear after 15 minutes. Monetisation should accelerate satisfying progression, not sell escape from boredom.

**Status:** modelling/research specification, not a completed balance implementation or playtest. Every cited competitor rate is source- and version-specific; never assume another game's unpublished retention/conversion metrics.

## Evidence and source strength

| Reference | Observed or published number | Confidence |
|---|---|---|
| [Slayer Legend 2024 Reddit response](https://www.reddit.com/r/SlayerLegend/comments/1c5zqvs/) | One player says 9,000 diamonds/day from quests/mail (3k + 6k), perhaps ~20k with 24/7 active farming. | **One historical anecdote, NOT current 2026 guaranteed gifts**. Online and offline sources must be separated. |
| [Idle Slayer purchase catalogue wiki](https://idleslayer.fandom.com/wiki/In-App-Purchases) | Examples: permanent +12% Coins/Souls, +30% offline CpS, and short-lived larger accelerators. | Community-maintained examples, not verified conversion/revenue or an endorsed price. |
| [Guild Wars 2 WvW](https://wiki.guildwars2.com/wiki/World_versus_world) | Three-team war scoring and objective ticks; monthly population rebalancing in current team building. | Established reference design, **not** proof of retention impact in our genre. |
| [GameAnalytics 2026 benchmarks](https://www.gameanalytics.com/cn/reports/2026-mobile-pc-gaming-benchmarks) | Games across genres: 2025 global median D1 ~22%, D7 under 4%, D30 ~0.7–0.8%; top 1% D30 ~13–15%. | Industry aggregate, **not** Slayer Legend/Idle Slayer/our game's measured retention. Title-specific paid conversions, lifetime value, median days-to-level, exact free currency rates **unknown until investigated directly**. |

## Mathematics to implement and verify

**1. Small incremental stats.** If upgrades independently multiply total power by 1.01, `P(n)=P(0)×1.01^n`. At 100 upgrades, power is ~2.70×; at 1,000 upgrades, ~20,959×. Thus even tiny repeatable multipliers can accelerate wildly. Prefer carefully specified additive upgrades within a limited stat bucket, diminishing effective marginal gain, tier-bound soft caps and separate systems with documented stacking order. Never silently nerf purchased value later.

**2. Constant affordability, without infinite one-shot strength.** For upgrade track `i`, record `cost_i(n)`, real effective-stat gain `Δpower_i(n)`, idle earnings rate `E(resource, stage, build)` and **time-to-next-useful-upgrade** `TTU_i = (cost - balance) / net earnings` when net earnings > 0. Also compute normalized strength gain `ΔP/P`, actual combat time, survivability, boss success and stage unlocks. If the cost of every next useful upgrade approaches infinity while earnings remain bounded, the system inevitably stalls: introduce another earnable attainable track, or adjust the curve. Don't hide an impassable wall behind a cosmetic number increment.

**3. Layer multiple clocks:** micro (test every few minutes initially), one-session character improvement, daily content/build advances, weekly meaningful milestones, and multiweek/month-long collections or prestige. These are initial **design hypotheses, not observed benchmarks**. Avoid “only one more milestone in three weeks.” A satisfying 30-second check should show progress even if the player did not open the app for a whole day.

**4. Evaluate fatigue at distribution tails:** median, P75, P90 and unlucky P99 time-to-next-upgrade; maximum continuous wall-time with no *meaningful* improvement; number of player choices; rate of exciting rewards. Do not accept a model in which “millions of coins earned” substitutes for an actual upgrade. Define **meaningful** through combat/survival/choice, not only new UI digits.

**5. Compare free play and purchase stacks.** A paid permanent 2× income bonus can shorten a gold-funded upgrade, but reinvesting it may increase future earning rates. Compute `time_to_goal(free)` and `time_to_goal(buyer)`, both with active and offline schedules, without assuming a linear 2× gain. Model XP bonus effect on levels and talent unlocks separately from source multipliers. Never grant global war score or normalized-PvP wins via purchase alone.

**6. Gacha expectation/uncertainty.** Report pulls per day from quests, passive idle, onboarding, events, duplicates, passes, ads (if any), paid grants and developer tools **separately**. For each target item, simulate rarity odds, pity state, banner pool, selected-item guarantee and duplicates; report mean/median and unlucky P90/P99 pulls. Measure useful rather than merely novel draws. Track catalogue saturation and enhancement-material sinks.

**7. XP curve, fights, offline parity.** Calculate expected levels by hour/day/season with simulated kill counts, route time, XP per enemy, finite talents and character damage relative to enemies. Test a real fresh **non-debug** save at 5min/15min/1h/1d/7d/30d/90d/180d, with 30-second check-ins, 2 daily short sessions and active 24/7 scenarios. Watched/offline grant parity remains mandatory. A healthy idle game cannot require leaving Android on overnight to make reasonable progress.

**8. Retention evidence.** D1 = players who return on calendar day 1 / starting cohort; similarly D7/D30. Record local measured cohorts once we actually have testers and eventually server telemetry. Never infer game-specific retention from reviews, downloads, community playtime anecdotes or simulated bot returns. Compare actual cohorts to dated industry data with genre/platform caveats. Track returner war-result interest separately from obligation/FOMO.

## Competitor replication protocol

For **Slayer Legend**, **Idle Slayer**, and at least one adjacent idle RPG, record observed fresh-start gifts, quest rewards, pull price, free pulls/day, online vs offline yields, event rewards, boost terms, purchased permanent upgrades and how long it takes a free/light-spend account to clear explicit milestones. Source each table cell from a dated actual game version, official documentation, current store, reliable wiki, timestamped video or clearly-labelled player report. Do not copy another game's prices/rates or rely on one anecdote. Use screenshots/saved capture when possible. Ensure the same daily activity schedule is compared.

**Validation acceptance** before claiming pacing fixed:
- First 15 minutes do not max every build or full legendary gear via normal economy; trace developer/debug currency separately.
- On every tested active/offline return interval, there is a useful affordable next improvement in at least one ordinary earned path (not necessarily a spectacular legendary every time).
- First 1/7/30 days retain meaningful *distinct* quests, boss counters and build decisions rather than just larger numbers.
- No model shows a long total upgrade drought, stat runaway, infinitely easy enemies or gold with no use.
- Paid entitlements have documented, bounded consequences over multiple months and do not buy faction victories.
- Actual Android owner playtest is required; model success **isn't** evidence of fun or retention.

For technical references see [ECONOMY_BASELINE.md](ECONOMY_BASELINE.md), [FRESH_SAVE_PROGRESSION.md](FRESH_SAVE_PROGRESSION.md), [MONETISATION_STUDY.md](MONETISATION_STUDY.md), [FACTION_WARFARE.md](FACTION_WARFARE.md) and [P0 issue #45](https://github.com/gabebartolo-spec/Idlerpg/issues/45).
