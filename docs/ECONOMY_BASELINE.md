# Economy baseline (IRPG-R01)

What the economy that is in the game today does over 1, 7, 30, 90 and 180 days, measured by
driving the real game code with a scripted player.

**Out of date for progression:** these results were measured before Old Thornback gained ranks and world items gained effects ([BOSS_AND_WORLD_ITEMS.md](BOSS_AND_WORLD_ITEMS.md)). Levels, gold, deaths and "nothing resists the adventurer" below describe the game before that change. The draw and collection findings are unaffected. Rerun the tool before relying on the progression figures.

**Status:** the model, its inputs and its results are checked in and reproducible. The
player research the ticket asks for has **not** been done (see "Not done").

- Inputs: [`tools/economy/inputs.json`](../tools/economy/inputs.json)
- Results: [`economy/baseline_results.json`](economy/baseline_results.json)
- Tables: [`economy/baseline_tables.md`](economy/baseline_tables.md) (generated)
- Model: `tools/economy/baseline_model.gd`; checks: `tests/test_economy.gd`

Rerun with:

    godot --headless --path . -s res://tools/economy/baseline.gd

The full run takes about 25 minutes on the development PC. The same inputs give the same
files.

## What is in the game today

| | |
|---|---|
| Summon tokens | 250 at the start; 10 per draw |
| Token income | none, apart from salvaging duplicate gear (1 / 2 / 5 / 15 tokens by rarity) |
| Gold | earned from quests; nothing to spend it on |
| Gear banner | 25 items, plus 3 world drops |
| Companion banner | 10 companions; one travels with the adventurer |
| Relic banner | 10 relics, which have no effect in play |
| Talents | 12; one point per level after the first |
| Adventurer | +1 attack and +5 health per level, with no level cap |

The simulation has no randomness. The only random part of the game is the draw.

## How it was measured

**The scripted player** learns talents in catalogue order as points arrive, spends every
token as soon as it has ten, draws one at a time in a fixed banner pattern (6 gear, 4
companions, 2 relics in every 12), equips any gear that scores higher (attack counts
double), salvages duplicate gear and spends the tokens again, and travels with its
highest-rarity companion. It is one policy, not a player. It never saves tokens and never
favours a banner.

**Two samples per cell:**

- *Collection:* 1,000 accounts for 180 days, checked once a day. Draws, collection and
  tokens only.
- *Progression:* 3 accounts simulated step by step for 30 days through the real
  simulation, then projected to 90 and 180 days at the last measured experience rate.

**Cohorts** are assumptions made for this analysis. They are not prices, offers or plans.

| Cohort | Tokens added |
|---|---|
| free | none |
| light | 300 on day 1 and every 30 days |
| high | 1,500 on day 1 and every 7 days |

**Income scenarios:** `implemented` (no income, the game as it is) and
`proposed_120_per_day` (120 tokens a day to everyone, a placeholder rate to show
sensitivity, not a recommendation).

**Terms.** A draw is *new* if the item was not owned before. It is *useful* if it was
equipped as an upgrade or became the travelling companion. *No effect* is a relic.

**Checks.** For every account, tokens started + purchased + income + salvaged − spent
equals the balance, and gold equals quest gold. The run had no ledger failures.

## Findings

### 1. A free player's draws end on day one

A free account makes about 25 draws on the first day and none afterwards. Its collection
stops at 8.8 of 25 gear, 4.7 of 10 companions and 3.1 of 10 relics, and 3.4% of accounts
hold the chosen target item (Crownblade). Salvage returns 2% of the tokens spent, so it does
not sustain drawing.

### 2. New is about twice as common as useful, and both run out

| Free, 120 tokens a day | Draws a day | New | Useful |
|---|---:|---:|---:|
| Day 1 | 37.5 | 55.2% | 23.8% |
| Days 2–7 | 12.7 | 14.7% | 5.2% |
| Days 8–30 | 13.0 | 3.3% | 1.5% |
| Days 31–90 | 13.2 | 0.4% | 0.2% |
| Days 91–180 | 13.2 | 0.0% | 0.0% |

After the first month, at this rate, a player draws 13 times a day and gets something useful
about once every five days; after day 90, about once a year. One draw in six is a relic that
does nothing at any point.

### 3. The catalogue saturates; a higher rate only moves the date

| Gear banner complete | Day 30 | Day 90 | Day 180 |
|---|---:|---:|---:|
| free, implemented | 0% | 0% | 0% |
| free, 120 a day | 3.0% | 73.8% | 98.4% |
| high, implemented | 44.2% | 97.3% | 100% |
| high, 120 a day | 75.9% | 99.6% | 100% |

Companions are all owned by day 30 in every cell with income. Once the catalogue is
complete, every draw is a duplicate worth at most 15 tokens. The high cohort spends about
43,000 tokens over 180 days and gets about 9% back as salvage. There is no reward path for a
complete collection.

### 4. Gear barely matters next to levels

| Free, implemented | Level | Attack | Of which gear |
|---|---:|---:|---:|
| 1 hour | 42 | 61 | 11 |
| Day 1 | 214 | 233 | 11 |
| Day 7 | 566 | 585 | 11 |
| Day 30 | 1,173 | 1,192 | 11 |

The best possible gear set gives 34 attack and 83 health. That is a real share of power in
the first hour and under 3% of it by day 30. Levels have no cap and experience arrives at a
steady 28,000 to 30,000 an hour, so the projection reaches about level 2,900 at day 180.

### 5. The power gap from spending is small and shrinks

Attack of each paying cohort divided by the free cohort's, same income scenario:

| | 1 h | Day 1 | Day 7 | Day 30 | Day 90 (projected) | Day 180 (projected) |
|---|---:|---:|---:|---:|---:|---:|
| light, implemented | 1.158 | 1.034 | 1.010 | 1.001 | 0.997 | 0.996 |
| high, implemented | 1.272 | 1.063 | 1.021 | 1.029 | 1.024 | 1.022 |
| light, 120 a day | 1.059 | 1.011 | 1.000 | 1.002 | 1.003 | 1.003 |
| high, 120 a day | 1.153 | 1.036 | 1.008 | 1.013 | 1.009 | 1.008 |

This follows from finding 4. It holds **only because gear is nearly irrelevant**. It is not
evidence that the draw is fair: any change that makes gear matter (a level cap, percentage
bonuses, content tuned to gear) will widen this gap, and the token cap on sources would not
bound it. Rerun this model when that happens.

Differences of under about 1% here are within the spread between three accounts and should
not be read as a direction. Paying accounts are sometimes a level or two behind free ones at
the same hour; the cause was not investigated.

### 6. Nothing resists the adventurer

No account in any cell died in 30 days. The first boss falls 40 to 50 seconds in. All 12
talents are learned within seven to eight minutes, after which talent points have no use.
There are no boss walls and no build decisions that last beyond the first ten minutes.

### 7. Gold only accumulates

About 160,000 gold on day 1, 1.1 million by day 7 and 4.8 million by day 30, with nothing to
spend it on.

## What this means for the roadmap

These are observations for the tickets that own the decisions, not decisions.

- A recurring token source is needed before drawing is a returning-player activity at all.
- A token rate alone cannot fix saturation; with 45 items, any rate that feels generous
  empties the catalogue within one to three months. The ticket rules out "endless stronger
  items", so the answer has to be a different kind of reward for a complete collection.
- Level growth needs bounding, or gear, talents and companions cannot matter.
- Gold needs a sink, and relics need a purpose or to leave the draw pool.

## Limits

- One scripted policy. Real players save, chase and ignore things.
- The cohorts and the 120-a-day rate are invented for sensitivity.
- Progression uses three accounts per cell. That is enough because the simulation is
  deterministic and accounts differ only in what they drew, but small differences are noise.
- Days 90 and 180 for level, attack and health are projections. The check column in the
  tables shows the method predicting day 30 to within about 1%.
- "Useful" means the scripted player equipped it by a simple score. It does not measure
  whether a player would want it. "New viable builds" was not measured: with every talent
  learned in minutes and gear this small, the game has no distinct builds to count.

## Not done

- **Playtests.** The ticket asks for 8 to 12 formative seven-day playtests when recruitable.
  None were run. Nothing here says whether the game is enjoyable.
- **Boosts, extra-draw effects and drop access.** These do not exist in the game, so there
  was nothing to model. Reinvestment is covered (salvage).
- **Population and contribution analysis** is R43's.
