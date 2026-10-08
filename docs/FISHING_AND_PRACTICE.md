# Mossgate Pond and practice preparation

R15 is a local desktop prototype, pending phone controls and player validation. Selecting Fishing queues a peaceful pause after the current outing finishes. Leaving the pond resumes ordinary adventures without discarding ingredients or partial cast progress. This is an activity choice: combat and quest rewards pause, while time-based summon income continues.

Every 15 simulated seconds, the pond supplies a deterministic perch → carp → herb rotation. Passive fishing supplies every ingredient. Two perch, one carp and one herb prepare a Pond Stew, intended to heal 12 party health once in the practice dungeon. Preparation consumes ingredients immediately and is saved atomically with the resulting stew count.

The optional reel button allows one attempt per cast. The green window is seven through nine seconds. Ten successful reels add one bonus perch; perfect active play adds at most one item per ten passive catches. Misses do not change the passive catch. Cast remainder, last attempted cast, successes and bonus grants persist, so reopening or changing activities cannot repeat a paid attempt. These timing/reward quantities are prototype assumptions.

Fishing catch-up counts the three-item rotation in constant work rather than stepping every cast. The existing seven-day offline cap and income settlement cursor continue to apply. Return reports show catch totals; first catches enter the chronicle. Save format 13 adds profession state; older saves start with an empty, inactive profession.

Verification includes queued activation, watched/offline equality, partial-cast reload, stop/resume, passive-only recipes, ingredient consumption, repeated/reloaded reel attempts, bonus bounds, seven-day work bounds and phone-sized UI actions. Actual desktop renders review the pond, ingredient inventory and preparation buttons. Touch timing and device performance remain to be measured on Android.

## Three-room NPC practice (R16)

The local practice dungeon has two ordinary rooms and a Moss Sentinel boss room. Bran is an NPC protector, contributing 36 party health, three damage and two blocked damage per enemy turn. Iris is an NPC support ally, contributing 24 party health, two damage and three healing every third turn. These are simulated allies, not real players or guild members.

The persistent adventurer chooses damage (+3 attack per turn), protection (block three per enemy turn), or support (heal ten every third turn). Attack and max health are frozen at entry, while identity and the same underlying hero remain intact. NPC health is represented by a combined party pool; this slice does not implement separate roster deaths or multiplayer. The Sentinel doubles incoming damage every fourth global party turn. Defeating an enemy prevents its attack that turn, making shorter fights useful. Recaps credit actual damage up to remaining enemy health, actual blocked damage and actual healing up to missing party health.

At most one Pond Stew is eligible per run. It is consumed only when the full 12-health restoration fits, and consumption is saved with the resulting encounter state. Leaving before use preserves it. Failure or cancellation grants no reward and resumes ordinary autonomous adventures; retries are free and must be selected explicitly. First victory gives 25 gold once and a chronicle milestone. Later victories give no repeatable first-clear gold.

[Role trials](economy/practice_role_trials.md) use controlled fixtures against the actual controller. At starting attack six and hero health 36, passive-earned stew enables protection/support victories while damage still loses. A Common Torch Sprite can enable a useful damage build without stew. These are prototype encounter observations, not multiplayer balance or paid-cohort fairness evidence.

Save format 14 stores queued and active runs, fractional turns, frozen roles/builds, contribution counters, recaps, stew use and first-clear settlement. Tests cover role/preparation counterfactuals, NPC contributions, watched/offline equality, interruption/reload, in-run stat changes, free repeat attempts, aborts and one-time gold. Main activity screens now keep concise choices and results; detailed rules and the contribution recap live in **Field journal → Field guide**. The NPC stage, compact screens and optional guide are rendered and inspected on desktop; real phone silhouette, timing, controls and performance remain VERIFY.
