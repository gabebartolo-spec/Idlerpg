# Collection pursuits and duplicate refunds — R10

Open **Gacha → Pursuit** and choose a missing item from the current banner. Before
confirming, the screen shows the expected and maximum gross token cost. Pursuits are
independent per banner. Switching to another item explicitly resets that banner's
progress; reselecting the same item keeps it. Drawing from another banner pauses it.

Every paid pull on that banner advances the pursuit. If the chosen item arrives in a
normal roll, the pursuit completes immediately. Otherwise pull 30 grants one additional
copy of the chosen item. The ordinary roll still pays and advances Legendary pity;
the bonus consumes no random draw and does not reset pity. Simultaneous guarantees
both pay. Acquired items cannot be chosen again, even if their gear copies were sold
or salvaged: permanent collection ownership does not disappear.

The maximum gross cost is 300 tokens for a new pursuit, declining with progress. When
a banner's sole Legendary item is due earlier through rarity pity, its cost bound is
tighter. Expected cost is the exact finite-horizon expectation from the published
68/22/9/1 rarity odds, rarity pool sizes, current Legendary pity and remaining route
budget. It includes possible natural hits before the guarantee. These are costs before
refunds; sufficient tokens for an entire multi-pull must be available upfront.

## Duplicates and saturation

Each ordinary duplicate refunds **one existing token**, retains its copy and contributes
to a cosmetic keepsake. New items and pursuit bonuses do not refund tokens. Developer
infinite draws do not mint refund tokens. Duplicate gear may still be salvaged through
the existing inventory action; companions and relics do not stack extra combat power.

| Gear rarity | Salvage tokens | With duplicate refund | Draw cost |
|---|---:|---:|---:|
| Common | 1 | 2 | 10 |
| Rare | 2 | 3 | 10 |
| Epic | 5 | 6 | 10 |
| Legendary | 8 | 9 | 10 |

Legendary salvage changes from 15 to eight to keep duplicate conversion below draw
cost. One-time pursuit bonuses cannot form a repeat loop: their target must be missing,
they cost up to 30 ordinary pulls and permanent ownership blocks reacquisition rewards.
No new currency, duplicate combat ranks or endlessly stronger items are introduced.

Fifty duplicates on a banner unlock its permanent cosmetic label: **Cache Curator**,
**Pact Keeper** or **Vault Archivist**. The label appears on that banner's Pursuit screen
and grants no stats or tokens. Counters stop at 50. Complete banners block item pursuit
and explain the optional keepsake; once both are complete, the UI says no collection
goal remains there. These are finite pursuits, not an endless reason to draw.

Save format **9** persists chosen items, partial progress and cosmetic counters.
Versions 1–8 retain all existing progress; they receive no retrospective refund or
cosmetic progress. Invalid, foreign-banner or already-owned targets are discarded.
Partial valid progress is constrained to 0–29. Gear, companion and relic ownership
continue to use their existing APIs, including guaranteed earned relics in the UI.

## Validation and economy limits

`test_collection_route.gd` covers worst luck, simultaneous guarantees, analytical cost
checks, JSON and actual checkpoint restore, multi-pull/serial parity, failed purchases,
switching, complete banners, developer wallets and conversion sinks. UI checks cover
touch selection, upfront costs, reset disclosure, completed banners and portrait bounds.

`tools/economy/collection_routes.gd` uses the real game and daily offline combat for
1/7/30/90/180-day sensitivity checkpoints. It runs one seeded account per cell: free,
light and high modeled purchases of 0/120/600 tokens per day, each under implemented
zero income and a hypothetical 120-token daily income. Purchases and daily income are
analysis assumptions, not live products or new earning rules. Every token ledger is
checked. Results and power-gap comparisons are in
[the generated sensitivity report](economy/collection_route_tables.md).

Useful draws mean an immediate increase in an autopilot's attack*2+maximum-HP score;
novelty is counted separately. A fixed banner pattern, greedy equipment score, companion
rarity preference and daily management do not represent human build choice. Travel
preferences, boosts, extra drop access, population tails and enjoyment are not modeled.
The results are sensitivity evidence rather than proof of fairness or retention.

All modeled accounts retain attainable free world counters. Functional collections
with recurring income saturate quickly, and no functional draw usefulness remains
after completion. Cosmetic keepsakes are also finite. This explicitly preserves R11's
earned-income question and later journal/cosmetic work rather than calling pull volume
enjoyment. Actual Android readability, pursuit swipes, restart/suspend and player
reward-recognition sessions remain VERIFY.
