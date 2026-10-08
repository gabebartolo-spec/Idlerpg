# Saves and offline catch-up (IRPG-R02)

How the game keeps a save safe and what happens to the time you were away.

**Status:** implemented and tested on desktop. The seven-day catch-up time on a phone has
**not** been measured; that reading is what closes R02 (see the end).

These saves are for single-player continuity. They are files and a clock on the player's
own device, so none of this can be trusted as online or competitive state. That is R28 and
R29's job.

## Files

Beside `user://idle_rpg_save.json`:

| File | What it is |
|---|---|
| `idle_rpg_save.json` | the save |
| `idle_rpg_save.json.bak` | the save before it, kept as a backup |
| `idle_rpg_save.json.tmp` | a save being written; normally gone a moment later |
| `idle_rpg_save.json.unreadable` | a save the game could not read, kept so it is never destroyed |

## Saving

1. The new save is written to the `.tmp` file, flushed, and read back to check it is complete.
2. The current save becomes the `.bak` file, but only if it still reads correctly, so a
   damaged save never replaces a good backup.
3. The `.tmp` file becomes the save.

A crash or a kill at any point leaves at least one complete file. If a save cannot be
written (no space, no permission), `save` returns false and the game says so on screen:
"Could not save. Progress since the last save may be lost."

## Loading

The game tries the save, then a `.tmp` file left by an interrupted write, then the `.bak`
file, and uses the first one that is complete. A file is rejected if it is not valid JSON,
has no version, is missing its `sim` or `game` section, or comes from a newer version of
the game.

What the player sees on the return screen:

| Situation | Message |
|---|---|
| The save was damaged and the backup was used | "Your latest save could not be read, so the one before it was restored." |
| Nothing could be read | "Your save could not be read, so a new adventure has started.", the reason, and that the unreadable save was kept |
| The device clock is behind the save | "The device clock is behind your last save, so no time away was counted." |
| The return could not be saved | "This return could not be saved yet." |

When nothing can be read, a damaged save is renamed to `.unreadable` before the new game
writes anything. Existing archives are preserved with numbered suffixes such as
`.unreadable.2`. Direct saves also preserve damaged primaries this way and stop if archival
fails. Versions and timestamps reject strings, fractions, booleans and invalid numbers.

A save from a newer build stays in place. Loading stops before falling back to older data,
and saving refuses to replace newer primary, temporary or backup data. The return screen
tells the player to update the game to continue. Rename helpers check the source before
removing a destination and return immediately if destination removal fails.

## Versions

`SAVE_VERSION` is 4. `_migrate` in `src/state/persistence.gd` upgrades older saves one
version at a time, and a loaded save is immediately rewritten in the current format.

| Version | Change |
|---|---|
| 1 | first format |
| 2 | the gacha generator's seed and state are saved in `game` |
| 3 | Old Thornback's rank, the boss fight tally and world hunts are saved in `sim`; numbers are written at full precision |
| 4 | bounded chronicle milestones, deduplication IDs and event sequence; legacy history is not fabricated |

A version 1 save loads with all its progress. It has no generator state, so it keeps a
freshly randomised generator, exactly as before.

## The gacha cannot be rerolled

The random generator's position is saved with everything else, as text because it is a
64-bit value that a JSON number cannot hold exactly. Closing the game and reopening it gives
the same next draws. The game already saved after every summon; before this change the
generator was re-randomised on every launch, so force-closing before a save could change
what came next.

## Rewards cannot be replayed

Returning writes a save straight after catching up, so opening the game twice counts the
time away once. This was already true and is still tested.

## The clock

Time away is `now - saved time`, capped at seven days.

- **Clock behind the save:** no time is counted, and the return says so.
- **The saved time never moves backwards.** Saving while the clock is wrong keeps the later
  timestamp. Without this, winding the clock back, saving, and winding it forward again
  would bank free offline time on every round trip.
- **The cost:** if a device clock was ever wrongly set ahead and the game saved, no offline
  time counts until real time passes that point.
- **Not handled:** setting the clock forward gains up to the seven-day cap. A device cannot
  detect that by itself. Server time (R28/R29) is the answer where it matters.

## Catch-up

Returning used to resolve every tenth of a second of the time away: about six million
steps for seven days.

The simulation has no randomness, so a quest cycle that starts from the same state plays
out the same way and takes the same number of steps. `simulate_offline` in
`src/sim/adventurer_sim.gd` uses that:

1. Step normally to the end of the quest cycle in progress.
2. Step through one whole cycle, recording the state at both ends.
3. If the two states are identical apart from the counters (gold, experience, kills,
   deaths, quests, loot, companion bond), that cycle will repeat exactly. Apply its result
   for as many cycles as fit before something would change: the next level-up, the next
   companion bond level, or the end of the time away.
4. Step through whatever changes, and measure again.

Anything that makes a cycle differ, including a new saved field nobody listed as a counter,
fails the comparison in step 3 and falls back to plain stepping. The failure mode is
"slow", not "wrong".

`simulate_elapsed` still steps one tenth of a second at a time and is the reference.
`tests/test_save_resilience.gd` requires the two to produce an identical saved state for a
new adventurer, a mid-fight start and a geared build with a companion, over times from a
fraction of a second to most of a day, and over a full day at high level. That test caught
one real fault during development: a companion reaching a new bond level part-way through
the measured cycle.

Repeated cycles do not emit events. The return report is built from the counters, and the
scene only starts listening for events after catch-up.

### Measured

On the development PC (Windows, Godot 4.7.2, headless), starting from a save one day into
the game:

| | Stepping | Catch-up |
|---|---:|---:|
| One day away | about 630 to 950 ms | 32 ms |
| Seven days away | about 6 s (from the earlier benchmark) | about 140 to 210 ms |

A phone will be slower by some factor that has not been measured. In debug builds the
return screen now shows "Dev: catch-up took N ms", so the reading can be taken on the
device.

## What closes R02

- [ ] On the Android device: leave the game for seven days (or use Dev > simulate away and
      a clock change) and record the "catch-up took N ms" reading, the device, the Android
      version and the build commit. The ticket asks for a measured device budget; there is
      not one yet.
- [ ] On the device: force-close during play and reopen; confirm progress and the next
      summon are as expected.
- [ ] Decide whether the seven-day cap should stay now that catch-up is cheap.

## Version 4: adventurer chronicle

Version 4 adds bounded milestone entries, a monotonic sequence and remembered first-event keys under `sim.chronicle`. Version 1–3 saves migrate without invented journal entries: existing loot, boss rank, owned gear and companion bond progress seed known firsts. Return highlights use the sequence loaded before catch-up; the ordinary immediate checkpoint persists both rewards and history, so an immediate reopen repeats neither. Quiet repeated cycles do not create milestones; cycles that change history cannot be batched. See [CHRONICLE.md](CHRONICLE.md).

## Versions 5–8: goals, policies, builds and relics

Version 5 adds three once-only goals and tracking. Older satisfied criteria seed completed markers without retroactive gold or invented history. Version 6 stores selected and current-outing policies separately, with the outing quarry and early-return flag. Older saves retain Push progression. Version 7 adds three empty optional named loadout slots. Version 8 adds one active relic and permanent guaranteed earned ownership; older progressed saves receive the opening-errand travel relic and first-boss health relic when their progress supports it, without auto-equipping. Empty relic choice in older presets remains valid.

Banner relic ownership stays in game collection; earned alternatives stay in simulation state, and presentation uses their union. After both sim and game restore, invalid/unowned active relics clear before catch-up. Loadouts validate ownership, slots, points and prerequisites before mutation. Selecting a policy mid-outing changes only the next outing. Goals, earned relics and presets participate in saved-state comparison, so catch-up cannot batch across an unrecorded transition. See [ADVENTURE_AND_BUILDS.md](ADVENTURE_AND_BUILDS.md).
