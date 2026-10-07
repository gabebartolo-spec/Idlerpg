# Adventurer chronicle and return highlights — R03

The chronicle remembers actual simulation milestones, whether watched or resolved offline. Open **Adventurer chronicle** from the watch view. Newest entries appear first; tap one, then use the pinned review action to open relevant management. The journal grants no rewards and never changes combat.

Recorded milestones:

- First goblin, wolf and briarling victory; the first boss victory has its own entry.
- First useful find for each gear item: more attack or health than the worn same-slot item, or an authored world effect. This identifies a build option, not an automatic best-choice recommendation.
- Each companion bond increase, once per companion and bond level.
- First close Old Thornback defeat: the boss had at most 25% health left. This is a historical loss; the Boss screen reviews current preparation and the most recent fight, not a historical replay.

The journal keeps up to 128 visible entries with monotonic IDs. Remembered first-event keys survive entry eviction, selling/reacquiring items and reload. The current catalog bounds these keys: ordinary fights, travel, quest cycles and unlimited level-ups do not create entries. There is no dialogue generation or full combat log.

After catch-up, the report selects up to three different milestone kinds from events after the loaded save's sequence. First boss victory takes precedence, then close defeat, useful gear, bond and ordinary first victory. Within a kind, the newest event wins. If fewer kinds occurred, show fewer highlights; never invent filler. Aggregate kills, quests, gold, levels, deaths and loot remain unchanged. Highlights sit above totals in a scrolling portrait sheet; talent spending remains pinned. Opening any management sheet closes the report.

Save version 4 stores the history and deduplication keys. Older saves start with an empty journal and remember firsts evidenced by existing loot, boss rank, owned gear and bond progress. They receive no retrospective entries or rewards. Immediate return checkpointing prevents repeating highlights on reopening at the same timestamp. Existing save failure/backup behavior still applies.

Offline batching only repeats cycles whose non-counter saved state is identical, including the chronicle. A cycle with a new milestone is stepped; quiet cycles may still batch. Companion threshold boundaries remain stepped. History and numeric IDs survive actual JSON round-trips.

## Validation

Godot 4.7.2 tests cover milestone deduplication and bounds, legacy migration, JSON restoration, close-defeat thresholds, aggregate reward preservation, repeated reopening, two-hour stepped/offline parity, seven-day catch-up, journal swipes in both directions and navigation. Existing persistence, boss and game suites remain required. Development-PC seven-day catch-up measured roughly 0.45 seconds; this is not an Android performance claim.

## Android verification still required

Record device, OS and exact build SHA. Check an empty journal, a populated journal, a return with no milestones and a long return with three highlights. Swipe each long list down and back up, confirm review controls stay reachable, verify gear/boss/companion destinations and Back to adventure, then suspend/resume and reopen again to check history and duplicate prevention. Record catch-up timing and screenshots. R00/R02's existing device checks remain open; R03 remains VERIFY until device evidence exists.
