# Idle RPG — Commercial purchasing and paid-acceleration research

**Owner direction, 9 October 2026:** A serious commercial game with **gacha token purchases as a central revenue driver**, complemented by permanent earning boosts, XP boosts, growth bundles, paid battle-pass loot and recurring timed events. Revenue is an ambition, not a proven prediction. No live prices or purchases are authorized by this study.

## Product hypotheses

| Concept | Buyer value | Balance/reliability condition |
|---|---|---|
| Permanent **2× gold from named sources** | An easy-to-understand lasting first purchase | Gold must have meaningful recurring sinks. Model compound effects (gold buys early gear, gear opens faster zones, faster zones generate more gold). Do not double tokens, rank or war score. 2× is a test case, not accepted balance. |
| XP booster (temporary or lasting) | Accelerate level and long-term upgrade trees | Simulate 1.25×, 1.5×, 2× across free/light/heavy cohorts as sensitivity tests; never auto-max all build branches or make paying mandatory. Define offline timer treatment and boost stacking. |
| Gacha-token packs | More choices, target items, companions, equipment, cosmetics | Long-term useful collection, meaningful duplicates, item identity, fair earning routes, explicit odds/pity/guarantees. Diagnostic separation of infinite developer tokens and paid economy is mandatory. |
| One-time growth path | Extra clearly described rewards at earned career milestones | Retroactively credit completed levels, no false expiry or purchase requirement to finish the base quest. |
| Monthly value pass | Predictable ongoing token/reward delivery and/or mild convenience | Clear renewal/terms; bank rewards so the player isn't compelled to log in daily to claim paid goods. |
| Seasonal free/premium pass | Paid extra materials, summons, appearances and loot previews | Keep previously decided **purchased-pass archive**, free attractive track, real progression paths and no paid-exclusive essential combat counters. |
| Timed events | Themed optional quests, special fights, rewards and optional event packs | Honest dates, real server schedule, opt-in, no fake scarcity or locked progression. New season/event content must be production-affordable. |

**Idle Slayer comparison:** its community-maintained [purchase catalogue](https://idleslayer.fandom.com/wiki/In-App-Purchases) lists permanent moderate bonuses including +12% Souls/CpS and +30% offline CpS; it also lists temporary larger earning boosts. These are examples of **offer types**, not verified actual sales effectiveness. **Slayer Legend comparison:** a [2024 player report](https://www.reddit.com/r/SlayerLegend/comments/1c5zqvs/) estimated ~9k free diamonds/day from quests/mail, potentially more from leaving the game running, but that is a **historical anecdote**, not a 2026 guaranteed rate.

## Monetisation is subordinate to playable progression

The owner's genuine 15-minute playtest exhausted builds and legendary items. First fix [P0 pacing #45](https://github.com/gabebartolo-spec/Idlerpg/issues/45) and distinguish debug summons from ordinary play. **An accelerator should save optional time, not repair a miserable free game.** Player should always be able to buy small useful in-game upgrades for earned gold/resources; see [PACING_MATH_AND_BENCHMARKS.md](PACING_MATH_AND_BENCHMARKS.md).

Mathematical review must cover full offer stacking: permanent gold bonus × temporary gold × pass/event loot × higher-zone unlocks; XP boost × innate gains × companion modifiers; paid/free tokens × target protection × duplicate conversion × upgrade materials × higher-stage income. A 2× rate can cause far more than a 2× total improvement through reinvestment. Specify exactly which resource and activity each entitlement alters. Competitive faction/arena results **must not be directly purchasable**; see [FACTION_WARFARE.md](FACTION_WARFARE.md).

R01/R43: simulate non-debug free, first-purchase, light monthly and high-spend accounts at 15min, 1h, 1d, 7d, 30d, 90d, 180d. Evaluate expected/unlucky useful rolls, duplicate paths, upgrade intervals, boss wins, gold sinks, progression saturation, paid/free power gaps and war contribution. Mock R22 shop before R23 boost approval. Eventually verify R25 payments, refunds, restoration, idempotent grants and server-controlled entitlements.

**Commercial math:** actual net revenue = paying users × average paid revenue - fees/refunds/operations; viable acquisition depends on net cohort LTV exceeding customer acquisition cost. Measure actual retention, conversion, repeat purchase, revenue per active user, net LTV, spend concentration and offer satisfaction. Simulated clicking and external game reviews are **not** measured purchase conversion.

**Trust/regulation:** [Google Play policy](https://support.google.com/googleplay/android-developer/answer/18258653) requires randomized virtual-item odds near and before purchases, true terms and pricing and compliant billing. Consult country-specific consumer and classification rules, ensure no false discounts/urgent timers or compulsive failure-to-purchase prompts. The game may be aggressively ambitious commercially without deceptive or coercive design.
