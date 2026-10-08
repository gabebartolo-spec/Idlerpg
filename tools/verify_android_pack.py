"""Check Android export resources without an SDK, APK, or normal game save.

This checks desktop execution of the Android preset's resource pack. It does
not establish Android installation, hardware rendering, touch feel or enjoyment.
"""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import uuid
import zipfile

ROOT = Path(__file__).resolve().parents[1]
TESTS = ("test_launch", "test_art", "test_reward_chests", "test_playtest_progression")
EXCLUDED = ("tests/", "tools/", "docs/", "server/", "art/", ".github/")


def run(command: list[str], cwd: Path, label: str) -> str:
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True, timeout=90)
    output = result.stdout + result.stderr
    if result.returncode or re.search(r"^(?:SCRIPT ERROR:|ERROR:)", output, re.MULTILINE):
        raise RuntimeError(f"{label} failed ({result.returncode}):\n{output}")
    return output


def verify(godot: str) -> dict:
    # Copy runtime inputs, not .godot caches. A new project identity prevents
    # test_launch's deliberate save cleanup from reaching the owner's save.
    with tempfile.TemporaryDirectory(prefix="idle-android-pack-") as temporary:
        base = Path(temporary)
        project = base / "project"
        project.mkdir()
        for directory in ("assets", "src"):
            shutil.copytree(ROOT / directory, project / directory)
        for filename in ("main.tscn", "project.godot", "export_presets.cfg"):
            shutil.copyfile(ROOT / filename, project / filename)
        settings_path = project / "project.godot"
        settings = settings_path.read_text(encoding="utf-8")
        if re.search(r"^config/use_custom_user_dir\s*=\s*true", settings, re.MULTILINE):
            raise RuntimeError("Custom user directory needs explicit isolation before auditing")
        isolated_name = "Idle RPG Codex audit pack " + uuid.uuid4().hex
        settings, replacements = re.subn(
            r'^config/name=.*$', f'config/name="{isolated_name}"', settings, flags=re.MULTILINE
        )
        if replacements != 1:
            raise RuntimeError("Cannot isolate project identity")
        # A clean editor starts its custom theme before importing the fonts
        # that theme needs. Bootstrap imports with the default editor theme,
        # then restore the real setting for export and all runtime checks.
        bootstrap = re.sub(r"^theme/custom=.*\n?", "", settings, flags=re.MULTILINE)
        settings_path.write_text(bootstrap, encoding="utf-8")
        run([godot, "--headless", "--path", str(project), "--editor", "--import", "--quit"], project, "Clean resource import")
        settings_path.write_text(settings, encoding="utf-8")
        pack = base / "android-resources.zip"
        run([godot, "--headless", "--path", str(project), "--export-pack", "Android Debug", str(pack)], project, "Android resource export")
        with zipfile.ZipFile(pack) as archive:
            entries = sorted(archive.namelist())
            forbidden = [name for name in entries if name.startswith(EXCLUDED)]
            if forbidden:
                raise RuntimeError(f"Development files included in game pack: {forbidden}")
            for required in ("project.binary", "main.tscn.remap", "src/ui/safe_area.gdc"):
                if required not in entries:
                    raise RuntimeError(f"Missing exported runtime resource: {required}")
        empty = base / "empty"
        empty.mkdir()
        checks = {}
        for test in TESTS:
            output = run(
                [godot, "--headless", "--path", str(empty), "--main-pack", str(pack), "-s", str(ROOT / "tests" / f"{test}.gd")],
                empty, test,
            )
            assertions = len(re.findall(r"^PASS:", output, re.MULTILINE))
            if not assertions:
                raise RuntimeError(f"{test} produced no passing assertions")
            checks[test] = {"passed": True, "assertions": assertions}
            print(f"PASS: exported pack / {test} ({assertions} assertions)", flush=True)
        version = run([godot, "--version"], empty, "Godot version").strip()
        commit = run(["git", "rev-parse", "HEAD"], ROOT, "Source revision").strip()
        dirty = bool(run(["git", "status", "--porcelain"], ROOT, "Source worktree state").strip())
        return {
            "source_commit": commit,
            "source_worktree_dirty": dirty,
            "godot": version,
            "preset": "Android Debug",
            "scope": "Resource export and desktop runtime checks; not an APK or physical-phone test",
            "isolated_project_identity": isolated_name,
            "pack_sha256": hashlib.sha256(pack.read_bytes()).hexdigest(),
            "pack_bytes": pack.stat().st_size,
            "entry_count": len(entries),
            "excluded_development_files": True,
            "runtime_checks": checks,
            "entries": entries,
        }


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", required=True)
    parser.add_argument("--report", type=Path)
    args = parser.parse_args()
    executable = shutil.which(args.godot)
    if executable is None:
        raise SystemExit(f"Godot executable not found: {args.godot}")
    report = verify(str(Path(executable).resolve()))
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print("Android resource pack verified; APK/device evidence remains separate.")


if __name__ == "__main__":
    main()
