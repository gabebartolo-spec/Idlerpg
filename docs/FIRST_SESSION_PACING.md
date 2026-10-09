# First-session pacing (issue #45)

The owner's report: after about 15 minutes on an Android build, every build was maxed and the
legendary items were all worn. This note measures an ordinary new save on current `main`,
explains what the code does, and lists the decisions that are the director's. **No game values
were changed.** The issue asks for the director to review a pacing curve before any reward
duration is fixed.

## What was measured

`tools/economy/first_session.gd` plays a brand-new save through the real game code with
developer features untouched (`dev_infinite_tokens` stayed off in every run). Rerun it with
`godot --headless --path . -s res://tools/economy/first_session.gd` (about 80 seconds).
Medians of five seeds are in [economy/first_session_tables.md](economy/first_session_tables.md).
It is one scripted policy, not a person.

| When | Level | Talents of 12 | Attack | Health | Legendary worn | Deaths |
|---|---:|---:|---:|---:|---:|---:|
| 5 min | 10 | 9 | 33 | 131 | 0 | 0 |
| 15 min | 21 | 12 | 44 | 186 | 0 | 2 |
| 1 hour | 39 | 12 | 62 | 278 | 0 | 21 |
| 24 hours | 188 | 12 | 212 | 1,025 | 0 | 170 |
| 7 days | 496 | 12 | 529 | 2,585 | 1 | 481 |

(All 250 starting tokens on the gear banner, the best case for gear.)

## Findings

1. **Talents: confirmed.** All 12 talents are bought by about minute 8 and every point after
   that has nothing to buy. No build tradeoff survives, which is the first half of the
   owner's report.
2. **Legendary gear in 15 minutes does not happen in ordinary play.** With the 250 starting
   tokens (25 draws at a 1% legendary rate) none of the 10 simulated saves owned a single
   Legendary at 15 minutes, and the best saves wore four Epic or Legendary pieces at most.
3. **A likely explanation for the legendary half, not yet confirmed.** The only export preset
   in the repo is `Android Debug` (`build/idle-rpg-debug.apk`), and `dev_tools_available()` in
   `src/game.gd` is true for any debug build. A debug APK therefore shows the infinite-token
   switch, the +10,000 token button and the 100-pull test. Whether the owner's 15-minute
   save used them is a question for the owner; the numbers above say the starting tokens alone
   cannot do it.
4. **Levels climb without a ceiling.** `xp_to_next_level()` is `level * 30` and a level gives
   +1 attack and +5 health, so power rises about linearly forever: level 21 at 15 minutes,
   level 188 at a day, level 496 at a week. Gear adds 16 to 26 attack at every checkpoint,
   which is under 10% of attack after the first hour. That is why items stop mattering.
5. **No pressure from enemies.** Zero deaths in the first 5 minutes and two at 15 minutes;
   the deaths that follow are the boss, which is beaten again and again (26 kills by
   minute 15). Nothing in the first hour asks the player to change gear or build.

## Decisions for the director

These are questions, not recommendations; the issue requires owner review before any number
is fixed. Your 10 October answers also change the ground under them: six classes will replace
the single talent tree, and prestige is wanted later.

1. **Target feel at the checkpoints.** For each of 15 minutes, 1 day and 1 week, what should a
   player have: how many build points spent or still locked, which gear rarity, how many
   goals in sight?
2. **Talent points versus talent nodes.** Today points equal nodes, so everything is bought.
   Options: fewer points than nodes so a branch must be chosen (with free respec, which
   already exists), or more nodes per class. With six classes this is a decision for the
   class design, not for the current Wayfarer-era tree.
3. **How steeply XP rises.** The current line is linear in level. A steeper line slows the
   first hour; a flat early line with a steep later one keeps the first session rewarding.
4. **When the first legendary can arrive.** Your rule: a new account must not wear a full
   legendary set in minutes, while free play still gets a bounded path to selected items.
5. **Developer tools in the APK.** Should owner test builds hide the debug panel unless
   switched on, so a playtest measures the real economy? This is separate from pacing and
   cheap to do.

## Not done

- No rebalance, no change to XP, talents, loot or enemies.
- No free-versus-spender comparison; `docs/ECONOMY_BASELINE.md` still holds the older
  tables, which its own banner says predate the boss ranks.
- Nothing here measures a real person. The owner's phone playtest after a rebalance is the
  required check.
