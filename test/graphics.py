"""Run the native smoke test with a display; keep screenshots out of the repo."""

import os
from pathlib import Path
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
font = Path(os.environ.get("RAYLIB_TEST_FONT", "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf"))
if not font.is_file():
    raise SystemExit("Set RAYLIB_TEST_FONT to an existing .ttf font")
with tempfile.TemporaryDirectory(prefix="raylib graphics ") as directory:
    subprocess.run(
        ["mojo", "run", "-I", str(root), str(root / "test/graphics.mojo"),
         str(root / ".pixi/raylib/lib/libraylib.so"), str(font),
         str(Path(directory) / "frame.png")],
        cwd=root, check=True, timeout=120,
    )
