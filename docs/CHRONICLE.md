# Adventurer chronicle and return highlights (R03)

Open **Chronicle** from the watch view to browse your adventurer's remembered milestones,
newest first. Each row shows the level and quest cycle when it happened; tap it to open
the relevant gear, companion, talents or boss screen. A sold item remains part of the
history, but its link cannot equip or recreate it.

The simulation records actual outcomes:

- The adventurer's first enemy victory and first Old Thornback victory.
- A useful gear acquisition: both base stats are at least as good as the worn item and
  one is better, or the item has a world effect worth inspecting. This is a build option,
  not a promise that equipping it always wins. Each item can be remembered once.
- A close defeat, when an enemy survives with at most 20% health. The recorded remaining
  health is real; one such moment is remembered per enemy kind.
- Each companion bond level gained through adventure, once per companion and level.

Stable milestone IDs prevent duplicates even when an old row falls out of history.
The newest 64 rows are retained. The ID set is bounded by the existing finite item,
enemy and companion catalogs; boss ranks and repeat kills do not grow it indefinitely.
Chronicle events grant no currency, items or other rewards.

On return, only events generated during that offline interval are considered. The three
highest-priority events are selected (first boss win, bond, useful gear, close defeat,
first kill); newer events break ties. The return sheet keeps the existing aggregate
totals in a scrolling region and provides direct milestone links, talent spending and
a history button. Opening any destination closes the report, so overlays do not stack.
A no-event return clears old highlights rather than inventing a story.

Save format **4** persists history, deduplication IDs and the event sequence. Versions
1–3 still load. Old kills, boss wins, owned gear and existing bond levels seed their
IDs without adding fictional historical rows. Unknown past events cannot be recreated.
Offline highlights are checkpointed with progression before the return report is shown;
reopening at the same timestamp repeats neither rewards nor highlights, while their
history rows remain browsable. Save failures continue to be reported visibly.

Catch-up preserves the same chronological events as watched simulation. Cycle batching
cannot skip a first milestone or a bond threshold: changed chronicle state prevents
batching that cycle, and existing bond boundaries still constrain repeat counts.

## Verification

`tests/test_chronicle.gd` checks watched/offline parity, real milestones, inferior gear,
duplicate and evicted IDs, legacy migration, bounded history, priority selection,
seven-day catch-up, aggregate totals and reopening without replay.
`tests/test_launch.gd` checks navigation and exclusive overlays; `tests/test_ui.gd`
checks touch links versus swipes, scrollable long reports, empty histories and portrait
layout. `tools/ui/capture.gd` includes chronicle and return screenshots for visual review.

Actual Android readability, touch feel, suspend/resume and device catch-up timing remain
VERIFY. Record device, OS and build SHA when completing the existing device checklist.
