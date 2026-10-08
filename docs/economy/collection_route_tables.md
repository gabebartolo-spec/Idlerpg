# R10 collection-route sensitivity results

Generated from collection_route_results.json by tools/economy/collection_routes.gd. Seed 101, one account per cell, real daily offline combat through day 180. Zero token ledger failures.

Purchases are hypothetical 0/120/600 tokens per day for free/light/high cohorts; income is either implemented zero or hypothetical 120/day. No live income rule or paid product is introduced. This small deterministic sample is not a population, enjoyment or fairness study.

Useful = an immediate increase in the autopilot's attack*2+HP build score. New items and route bonuses are counted separately. Saturation = all 45 banner items collected; earned relic alternatives are also available in the game but are not counted as banner draws.

| Cell | Day | Paid draws | New items | Useful draws | Route bonuses | Unique /45 | Saturated |
|---|---:|---:|---:|---:|---:|---:|---|
| free/income0 | 1 | 26 | 18 | 9 | 0 | 18 | no |
| free/income0 | 7 | 26 | 18 | 9 | 0 | 18 | no |
| free/income0 | 30 | 26 | 18 | 9 | 0 | 18 | no |
| free/income0 | 90 | 26 | 18 | 9 | 0 | 18 | no |
| free/income0 | 180 | 26 | 18 | 9 | 0 | 18 | no |
| free/income120 | 1 | 40 | 20 | 11 | 0 | 20 | no |
| free/income120 | 7 | 127 | 35 | 16 | 2 | 35 | no |
| free/income120 | 30 | 469 | 45 | 19 | 7 | 45 | yes |
| free/income120 | 90 | 1373 | 45 | 19 | 7 | 45 | yes |
| free/income120 | 180 | 2725 | 45 | 19 | 7 | 45 | yes |
| high/income0 | 1 | 97 | 32 | 15 | 1 | 32 | no |
| high/income0 | 7 | 543 | 45 | 19 | 7 | 45 | yes |
| high/income0 | 30 | 2276 | 45 | 19 | 7 | 45 | yes |
| high/income0 | 90 | 6778 | 45 | 19 | 7 | 45 | yes |
| high/income0 | 180 | 13524 | 45 | 19 | 7 | 45 | yes |
| high/income120 | 1 | 112 | 33 | 16 | 2 | 33 | no |
| high/income120 | 7 | 648 | 45 | 19 | 7 | 45 | yes |
| high/income120 | 30 | 2725 | 45 | 19 | 7 | 45 | yes |
| high/income120 | 90 | 8125 | 45 | 19 | 7 | 45 | yes |
| high/income120 | 180 | 16222 | 45 | 19 | 7 | 45 | yes |
| light/income0 | 1 | 40 | 20 | 11 | 0 | 20 | no |
| light/income0 | 7 | 127 | 35 | 16 | 2 | 35 | no |
| light/income0 | 30 | 469 | 45 | 19 | 7 | 45 | yes |
| light/income0 | 90 | 1373 | 45 | 19 | 7 | 45 | yes |
| light/income0 | 180 | 2725 | 45 | 19 | 7 | 45 | yes |
| light/income120 | 1 | 54 | 26 | 13 | 1 | 26 | no |
| light/income120 | 7 | 230 | 42 | 18 | 5 | 42 | no |
| light/income120 | 30 | 922 | 45 | 19 | 7 | 45 | yes |
| light/income120 | 90 | 2725 | 45 | 19 | 7 | 45 | yes |
| light/income120 | 180 | 5425 | 45 | 19 | 7 | 45 | yes |

## Resulting combat power relative to the free cohort

| Cell | Day | Level | Attack | HP | Attack / free | HP / free | Boss rank | Free counters owned |
|---|---:|---:|---:|---:|---:|---:|---:|---|
| free/income0 | 30 | 1088 | 1113 | 5554 | 1.0000 | 1.0000 | 925 | yes |
| free/income0 | 90 | 1891 | 1916 | 9569 | 1.0000 | 1.0000 | 1593 | yes |
| free/income0 | 180 | 2676 | 2701 | 13494 | 1.0000 | 1.0000 | 2247 | yes |
| free/income120 | 30 | 1057 | 1102 | 5451 | 1.0000 | 1.0000 | 726 | yes |
| free/income120 | 90 | 1835 | 1880 | 9341 | 1.0000 | 1.0000 | 1239 | yes |
| free/income120 | 180 | 2597 | 2642 | 13151 | 1.0000 | 1.0000 | 1742 | yes |
| high/income0 | 30 | 1057 | 1102 | 5451 | 0.9901 | 0.9815 | 726 | yes |
| high/income0 | 90 | 1835 | 1880 | 9341 | 0.9812 | 0.9762 | 1239 | yes |
| high/income0 | 180 | 2597 | 2642 | 13151 | 0.9782 | 0.9746 | 1742 | yes |
| high/income120 | 30 | 1057 | 1102 | 5451 | 1.0000 | 1.0000 | 726 | yes |
| high/income120 | 90 | 1835 | 1880 | 9341 | 1.0000 | 1.0000 | 1239 | yes |
| high/income120 | 180 | 2597 | 2642 | 13151 | 1.0000 | 1.0000 | 1742 | yes |
| light/income0 | 30 | 1057 | 1102 | 5451 | 0.9901 | 0.9815 | 726 | yes |
| light/income0 | 90 | 1835 | 1880 | 9341 | 0.9812 | 0.9762 | 1239 | yes |
| light/income0 | 180 | 2597 | 2642 | 13151 | 0.9782 | 0.9746 | 1742 | yes |
| light/income120 | 30 | 1057 | 1102 | 5451 | 1.0000 | 1.0000 | 726 | yes |
| light/income120 | 90 | 1835 | 1880 | 9341 | 1.0000 | 1.0000 | 1239 | yes |
| light/income120 | 180 | 2597 | 2642 | 13151 | 1.0000 | 1.0000 | 1742 | yes |

The no-income free account stops at 26 draws and 18 unique items. Cells with recurring tokens reach functional saturation by day 30; cumulative useful draws then stop increasing. The cosmetic keepsakes are finite and grant no power. These outcomes support examining earned income in R11 and later cosmetic/journal pursuits, not inflating duplicate stats.

Some purchased cohorts have less modeled power than the free cohort: greedy companion rarity and attack/HP choices do not optimize travel or encounter progression. Uncapped levels dominate long-term stats. This is a limitation of the current autopilot and progression model, not proof that spending is harmless. Boosts, extra drop access, player build choices and population tails are excluded.
