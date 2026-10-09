# Watch camera: orbit and zoom

Issue [#43](https://github.com/gabebartolo-spec/Idlerpg/issues/43). The camera still follows the
adventurer on its own. The player can now turn it and move it closer or further, so a large tree
in front of the action can be cleared with a swipe or a pinch.

## Controls

| Input | Effect |
|---|---|
| One finger, drag sideways | Orbit the adventurer. Dragging right pulls the world with the finger. |
| Two fingers, pinch | Fingers apart zooms in, fingers together zooms out. |
| Mouse drag (desktop) | Orbit. The project turns mouse drags into touches, so this is the same code path. |
| Mouse wheel (desktop) | Zoom. |

Only sideways movement turns the camera; height and tilt never change. Zoom runs from 0.55x to
1.6x of the default distance. Those two numbers and the turn speed are constants at the top of
`src/view/camera_rig.gd` and need tuning on a real phone.

## Rules

- **Only the open world counts.** A gesture begins only if the first touch lands outside the HUD
  card, the Gear/Talents/Summon/More row and any open sheet, report or menu. A swipe that starts
  on a control stays with that control, even if it ends in the world.
- **Sheets own every touch while open.** Opening one in the middle of a swipe ends the swipe.
- **Pinch never orbits.** The second finger cancels any swipe, and the finger left after a pinch
  cannot start an orbit until it has been lifted.
- **The camera only looks.** Nothing here moves the hero or reaches the simulation.
- **The choice sticks.** Angle and distance are stored apart from where the camera is, so walking
  to a new place, changing activity or entering the woodland trails does not reset them. The
  woodland camera is still closer, scaled by the chosen zoom. The choice is not saved to disk:
  it resets when the app restarts.
- **No inertia.** The turn and zoom apply on the same frame. The follow-the-hero easing is
  unchanged, and reduced motion adds no camera animation of its own.

## Backdrop

The hills and distant trees used to sit on one side only, where the old fixed camera looked.
`_build_horizon` in `src/main.gd` now closes the ring: 14 more hills and 24 more trees on the
far side, with the trees kept beyond the Lanternwood trails so they never stand on the route.
The first group is drawn exactly as before.

## Not done

- Trees do not fade when they sit between the camera and the hero. Orbit and zoom let the player
  clear them; automatic fading is a separate piece of work (the bible's R46 mentions it).
- Android portrait testing. Limits, turn speed and the protected areas are set from the code and
  headless tests only.
- The 24 extra trees were not checked against every Lanternwood prop by eye.

Tests: `tests/test_camera.gd`.
