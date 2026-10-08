# Phone display insets

The 3D world fills the display. The HUD, navigation and management sheets share a Control parent sized to Godot's unobscured display area on Android/iOS. Physical display pixels map back through the viewport screen transform, then intersect the viewport. Desktop windows use their full viewport. Missing or invalid device bounds fall back to the viewport.

Insets refresh on viewport resizing and every half second, including after system-bar changes or resume. Sheets that need extra height because of rendered font metrics expand upward toward the world, preserving their safe bottom edge. No saved progress or reward rules change. Existing sheet padding remains for touch comfort.

`tests/test_safe_area.gd` exercises a shifted/scaled screen transform, simulated top/bottom/side insets, an actual menu touch, large-text equipment actions, changed insets and invalid reports. `test_launch.gd` checks that the actual HUD, navigation and gear drawer share this parent. These are simulated layout checks, not evidence from a physical phone.

Owner phone check: in portrait, verify the HUD clears the camera notch and bottom navigation/Equip clears system bars. Toggle system navigation or suspend/resume if convenient. Report any overlap with the phone model and a screenshot.

API references: [DisplayServer safe area](https://docs.godotengine.org/en/4.7/classes/class_displayserver.html#class-displayserver-method-get-display-safe-area), [Viewport screen transform](https://docs.godotengine.org/en/4.7/classes/class_viewport.html#class-viewport-method-get-screen-transform).
