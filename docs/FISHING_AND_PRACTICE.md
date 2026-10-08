# Mossgate Pond and practice preparation

R15 is a local desktop prototype, pending phone controls and player validation. Selecting Fishing queues a peaceful pause after the current outing finishes. Leaving the pond resumes ordinary adventures without discarding ingredients or partial cast progress. This is an activity choice: combat and quest rewards pause, while time-based summon income continues.

Every 15 simulated seconds, the pond supplies a deterministic perch → carp → herb rotation. Passive fishing supplies every ingredient. Two perch, one carp and one herb prepare a Pond Stew, intended to heal 12 party health once in the practice dungeon. Preparation consumes ingredients immediately and is saved atomically with the resulting stew count.

The optional reel button allows one attempt per cast. The green window is seven through nine seconds. Ten successful reels add one bonus perch; perfect active play adds at most one item per ten passive catches. Misses do not change the passive catch. Cast remainder, last attempted cast, successes and bonus grants persist, so reopening or changing activities cannot repeat a paid attempt. These timing/reward quantities are prototype assumptions.

Fishing catch-up counts the three-item rotation in constant work rather than stepping every cast. The existing seven-day offline cap and income settlement cursor continue to apply. Return reports show catch totals; first catches enter the chronicle. Save format 13 adds profession state; older saves start with an empty, inactive profession.

Verification includes queued activation, watched/offline equality, partial-cast reload, stop/resume, passive-only recipes, ingredient consumption, repeated/reloaded reel attempts, bonus bounds, seven-day work bounds and phone-sized UI actions. Actual desktop renders review the pond, ingredient inventory and preparation buttons. Touch timing and device performance remain to be measured on Android.
