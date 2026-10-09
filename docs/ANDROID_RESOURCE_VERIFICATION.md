# Android resource verification

The owner exports the APK from Godot. Before that export, this check catches missing runtime resources and accidentally packaged development files without installing an SDK or JDK:

```text
python tools/verify_android_pack.py --godot <Godot console executable> --report <report.json>
```

The tool copies runtime inputs into a temporary project with a unique audit save identity. It starts with no import cache. The default editor theme is used only during initial asset import, because the original custom theme needs fonts that have not been imported yet. The real custom theme is restored before export and runtime checks. The project serializes editor resource imports to avoid the observed Godot 4.7 multi-font import crash; runtime threading is unaffected. See `TRIPO_PROCESS_LEARNINGS.md` for the failure evidence and upstream references.

It exports the existing Android Debug preset's resource ZIP, rejects tests/tools/docs/server/development-art files, and runs external test drivers against that ZIP from an empty directory. Loose source files cannot fill missing `res://` resources. The drivers check actual main-scene actions, all catalog models/icons, chest settlement and both scripted seven-day fresh-save acquisition/save-return schedules. They exercise compiled exported scripts, not a replacement simulation.

The JSON report records the source revision and worktree state, Godot version, resource-pack hash/size, complete entry list and passing assertion counts. CI saves this report as an artifact. The ZIP hash identifies a temporary resource pack; it is **not an APK hash**.

Verified locally on Godot 4.7.2: 50 launch assertions, 28 art assertions, 19 reward assertions and 148 scripted-progression assertions passed. This does not prove Android installation, hardware rendering, physical-phone timing, connectivity, desirability, enjoyment or voluntary returns. Those observations remain with the owner's playtest. No recruitment or daily log is needed.
