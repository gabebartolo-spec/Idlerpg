# Phone comfort

The watch view has one row: **Gear · Talents · Summon · More**. More holds the
remaining adventure activities and management screens in a touch-scroll list;
Options stays reachable at the bottom. Unspent talent points stay visible on
the main Talents button. Developer tools are only listed in development builds.
The same gear, quests, activities, collections and rewards remain available.

**Larger text** adds four logical pixels to reading labels, input fields and
button lettering up to size 26. Headings and single-line header subtitles keep
their layout sizes. New rows inherit the preference, and switching it off
restores the original sizes without cumulative growth.

**Reduced motion** removes limb swings, idle breathing, wing flaps, companion
bobbing, talent pulse effects, boss shudder and scroll inertia. World travel,
camera following, the defeated pose and a static boss windup cue remain: they
communicate resolved state and location. Both options can be switched back at
any time. They never change simulation clocks, RNG, combat, drops or income.

Save format 16 stores these booleans under `game.presentation`. Format 18 adds
independent opt-in Music/Sounds switches; see `docs/TRAIL_AUDIO.md`. Older saves
default to standard text/motion; malformed preference values are ignored.
Preferences are saved immediately when changed through Options and survive
ordinary close/reopen and offline settlement.

Tests cover save/reload, legacy/malformed values, live options leaving the full
simulation snapshot unchanged, rebuilding rows, repeated toggling, static and
ordinary poses, stopped scroll inertia and More navigation. The complete UI
input/layout suite also runs with Larger text enabled. Real 405 × 720 desktop
renders are inspected. Android sustained frames, memory, battery behavior,
real touch comfort and speaker/headphone balance remain open for R27.
