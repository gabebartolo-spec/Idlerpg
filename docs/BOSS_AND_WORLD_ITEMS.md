# Old Thornback, world items and hunts (IRPG-R08, IRPG-R09)

How the boss fights back, what a loss tells the player, and what the world gives that a
banner does not.

**Status:** implemented and tested headless. Not yet played on a phone; see "Still to check".

## Why

Before this, nothing in the game could beat the adventurer, levels outgrew every enemy
within minutes, and gear was a rounding error (see [ECONOMY_BASELINE.md](ECONOMY_BASELINE.md)).
A boss mechanic and item effects mean nothing unless a fight can be lost and an item can
change the result. So Old Thornback now keeps pace with the adventurer, and world items
work in proportions, not flat numbers.

## Old Thornback

Numbers are in `src/data/boss_catalog.gd`.

| | Rank 0 | Each rank adds |
|---|---:|---:|
| Health | 60 | 25 |
| Damage per attack | 4 | 1 |
| Experience for the kill | 40 | 5 |

- **Rank.** Each time Old Thornback is beaten it returns one rank stronger. Rank never
  goes down. A new adventurer beats rank 0 on the first attempt.
- **Thorn Burst (the telegraphed mechanic).** Every third attack is the burst, at three
  times the damage. After the attack before it, the boss raises its thorns: the log says
  so and the boss swells and shudders on screen until the burst lands.
- **Losing.** A lost fight ends the quest back in Mossgate with the smaller reward
  (25 gold and 20 experience, against 40 and 35 for a win). The adventurer then clears
  Briarlings and goes home each quest, and does not challenge again until something has
  changed: a level, the gear worn, talents, or the companion and its bond level. One loss
  per change, never a loop of defeats.
- **No tapping.** Everything above resolves by itself. Preparation is what the player
  chooses to wear and hunt.

## World item effects

Words for these are in `GearCatalog.EFFECTS`; the rules are in the simulation.

| Item | Slot | Effect | How it is earned |
|---|---|---|---|
| Briarheart Charm | accessory | **Thornward:** telegraphed blows deal half damage | Old Thornback drops one whenever you do not have it |
| Briarhook | weapon | **Opportunist:** hits deal double damage while the enemy is winding up | Hunt: Briarlings |
| Thornback Carapace | chest | **Hardened:** every hit taken deals 25% less damage | Hunt: Old Thornback |

The Charm and the Briarhook are the two counters to Thorn Burst: one takes less of it, the
other uses the warning to hit harder. The Carapace is the deeper push.

Highest rank beaten by the same adventurer with every talent (from `tests/test_boss.gd`):

| Level | Plain | Charm | Briarhook | Both | All three |
|---:|---:|---:|---:|---:|---:|
| 15 | 12 | 15 | 17 | 20 | 22 |
| 40 | 28 | 33 | 37 | 42 | 46 |
| 120 | 81 | 90 | 100 | 109 | 123 |

**Against banner gear.** Banner items have bigger flat numbers and no effects. At level 3 a
Crownblade beats rank 4 and a Briarhook rank 3; at level 120 the Briarhook beats rank 100
and the Crownblade 89. Neither replaces the other outright. The effects only matter against
Old Thornback, because nothing else winds up or hits hard enough to notice.

## Hunts

Definitions are in `src/data/hunt_catalog.gd`.

| Hunt | Quarry | Chance per kill | Certain by | Average kills |
|---|---|---:|---:|---:|
| Briarhook | Briarlings in Briarfen | 3% | kill 80 | about 30 |
| Thornback Carapace | Old Thornback | 10% | kill 20 | about 9 |

- **One hunt at a time.** Only the chosen hunt rolls. A new adventurer hunts the Briarhook;
  when a hunt pays out the adventurer moves to one that still has something to find.
- **Bounded bad luck.** Kills since the last drop are counted, and the drop is certain on
  the stated kill. About 9% of Briarhook hunts and 13% of Carapace hunts reach the bound.
  This count belongs to the hunt only. It shares nothing with banner pity and cannot be
  bought.
- **Rolls cannot be rerolled.** Each save has a seed, and roll number N of a hunt always
  gives the same result, so reloading changes nothing and watched and offline play agree.
- **Owned items are not hunted.** Sell one and it can be hunted again.
- **First discovery.** The first time each of the three items is found pays 200 gold, once
  per save. Selling and finding it again pays nothing more. A save from before this change
  counts world items it already owns as discovered.
- **Not a token source.** Items the world gives back salvage for 0 tokens. Before this, the
  Briarheart Charm could be salvaged for 2 tokens and regained on the next boss kill.
- **Never on a banner.** `tests/test_hunts.gd` checks no world item is in any banner pool.

## What a loss explains

`src/sim/boss_advice.gd` builds the explanation from a tally the simulation keeps during
the fight: damage dealt and taken, how many bursts landed and for how much, damage added by
striking during the wind-up, and the health the boss had left.

The Boss screen (the **Boss** button) shows:

- the result and rank, the boss's remaining health, and the burst's share of the damage;
- suggestions, most relevant first: unspent talent points; the Charm if the burst did 30%
  or more of the damage; the Briarhook if the boss was within 35% of dying; then the rest.
  An owned item is offered to equip in one tap, an unowned one as a hunt with its progress;
- when the adventurer will try again.

Suggestions only ever name talents, world items, hunts and levels. The test fails if any
text mentions a draw, a banner, tokens or a purchase.

## The free path

`tests/test_boss.gd` runs an adventurer with no draws and hunting switched off, following
only the one-tap equip suggestions. It owns just the three items every adventurer is given
and reaches rank 23 in 30 minutes with the quest loop never stalling.

## Watched and offline

Catch-up (`simulate_offline`) gives the same saved state as stepping for a new build and a
fully countered one over 47 seconds, 10 minutes, 1 hour and 4 hours. A boss fight, a rank
or a hunt roll changes saved state, so those quest cycles are stepped in full and only
identical cycles are repeated. Seven days of catch-up takes about 0.4 to 0.6 s on the
development PC.

Saves are now written with full number precision, so a game reloaded mid-fight plays on
exactly as it would have.

## Saves

`SAVE_VERSION` is 3. Version 2 saves load with rank 0, the default hunt, no fight history,
and owned world items counted as discovered. See [SAVE_AND_OFFLINE.md](SAVE_AND_OFFLINE.md).

## Limits

- One boss, one mechanic. Flat stats on gear are still tiny next to levels; only the three
  effects scale. Bounding level growth is a separate decision.
- The discovery reward is gold, which still has nothing to spend it on.
- The numbers are a first pass, tuned by simulation and not by play. Rank tracks at roughly
  0.7 of the adventurer's level for a plain build.
- The telegraph is a log line and a swell on the boss model. Whether it reads on a phone is
  unverified.
- The economy baseline (R01) was measured before this change; experience and gold rates
  have moved and it should be rerun before anyone relies on its progression figures.

## Still to check on a phone

- [ ] The wind-up swell is noticeable at phone size.
- [ ] The Boss sheet scrolls both ways and the action button is easy to reach.
- [ ] After a loss, the explanation and the first suggestion make sense without this document.
- [ ] Record device, Android version and build commit.
