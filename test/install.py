"""Install in an unrelated Pixi project and import without Mojo -I flags."""

import os
from pathlib import Path
import subprocess
import tempfile


root = Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory(prefix="raylib consumer ") as directory:
    consumer = Path(directory)
    (consumer / "pixi.toml").write_text(f'''
[workspace]
name = "raylib-consumer"
channels = ["https://conda.modular.com/max-nightly", "conda-forge"]
platforms = ["linux-64"]
preview = ["pixi-build"]

[dependencies]
raylib = {{ path = "{root.as_posix()}" }}

[tasks]
check = "mojo run main.mojo"
''')
    (consumer / "main.mojo").write_text('''
from raylib import Color, Window, Frame, Library, TextFont, Texture2D
from std.testing import assert_equal

def main() raises:
    var color = Color(12, 34, 56, 255)
    assert_equal(color.r, UInt8(12))
    print("External raylib import passed")
''')
    # Do not inherit an activated parent Pixi environment or import overrides.
    env = {key: value for key, value in os.environ.items()
           if not key.startswith("PIXI_") and key != "MOJO_PATH"}
    subprocess.run(["pixi", "run", "check"], cwd=consumer, env=env,
                   check=True, timeout=180)
