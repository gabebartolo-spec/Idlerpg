"""Launch disposable live service, then exercise its real Godot HTTP client."""
import argparse
import os
import socket
import subprocess
import tempfile
import threading
import time
from pathlib import Path

import uvicorn
from server.app import create_app


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--godot", required=True)
    parser.add_argument("--project", default=".")
    parser.add_argument("--script", default="tests/test_online_client.gd")
    parser.add_argument("--render", action="store_true")
    args = parser.parse_args()
    epoch = time.monotonic()
    with tempfile.TemporaryDirectory() as directory:
        with socket.socket() as listener:
            listener.bind(("127.0.0.1", 0))
            listener.listen(128)
            # Only this disposable verification server accelerates time. The
            # production factory always uses real server time and 24-hour raids.
            service = uvicorn.Server(uvicorn.Config(create_app(Path(directory) / "test.sqlite3", lambda: 1800000000 + int((time.monotonic() - epoch) * 8640)), log_level="error", access_log=False))
            thread = threading.Thread(target=lambda: service.run(sockets=[listener]), daemon=True)
            thread.start()
            try:
                for _ in range(200):
                    if service.started:
                        break
                    time.sleep(.01)
                if not service.started:
                    raise RuntimeError("Service did not start")
                env = {**os.environ, "IDLE_TEST_URL": "http://127.0.0.1:" + str(listener.getsockname()[1])}
                mode = ["--rendering-method", "gl_compatibility"] if args.render else ["--headless"]
                try:
                    run = subprocess.run([args.godot, *mode, "--path", args.project, "--script", "res://" + args.script], env=env, timeout=45, capture_output=True, text=True)
                except subprocess.TimeoutExpired as error:
                    # Preserve Godot diagnostics even when a script error left
                    # the engine running. communicate() has already killed it.
                    for output in (error.stdout, error.stderr):
                        if output:
                            print(output.decode(errors="replace") if isinstance(output, bytes) else output)
                    print("Godot verification timed out")
                    return 1
                print(run.stdout)
                print(run.stderr)
                return run.returncode or (1 if "SCRIPT ERROR" in run.stderr or "ERROR:" in run.stderr else 0)
            finally:
                service.should_exit = True
                thread.join(5)
                if thread.is_alive():
                    raise RuntimeError("Service failed to stop")


if __name__ == "__main__":
    raise SystemExit(main())
