"""Check that a separate Pixi consumer gets bindings, headers, and native raylib."""

import json
from pathlib import Path
import subprocess
import tempfile
import textwrap


def main():
    root = Path(__file__).resolve().parents[1]
    with tempfile.TemporaryDirectory(prefix="raylib consumer ") as tmp:
        consumer = Path(tmp)
        manifest = consumer / "pixi.toml"
        manifest.write_text(textwrap.dedent(f"""\
            [workspace]
            name = "raylib-consumer-test"
            channels = ["https://conda.modular.com/max-nightly", "conda-forge"]
            platforms = [{{ platform = "linux-64", glibc = "2.38" }}]
            preview = ["pixi-build"]

            [dependencies]
            raylib = {{ path = {json.dumps(str(root))} }}
            """))
        subprocess.run(["pixi", "install", "--manifest-path", str(manifest)], check=True)
        prefix = consumer / ".pixi/envs/default"
        assert (prefix / "lib/libraylib.so").is_file()
        for header in ("raylib.h", "raymath.h", "rlgl.h"):
            assert (prefix / "include" / header).is_file(), header
        (consumer / "native.c").write_text(textwrap.dedent("""\
            #include <raylib.h>
            #if RAYLIB_VERSION_MAJOR != 6 || RAYLIB_VERSION_MINOR != 2
            #error Unexpected native raylib version
            #endif
            int main(void) { return GetRandomValue(13, 13) != 13; }
            """))
        subprocess.run([
            "cc", str(consumer / "native.c"), f"-I{prefix / 'include'}",
            f"-L{prefix / 'lib'}", f"-Wl,-rpath,{prefix / 'lib'}", "-lraylib",
            "-o", str(consumer / "native"),
        ], check=True)
        subprocess.run([str(consumer / "native")], check=True)
        (consumer / "smoke.mojo").write_text(textwrap.dedent("""\
            from std.ffi import c_int
            from std.os import getenv
            from std.testing import assert_equal
            from raylib import Raylib

            def main() raises:
                var api = Raylib(getenv("CONDA_PREFIX") + "/lib/libraylib.so")
                assert_equal(api.GetRandomValue(c_int(13), c_int(13)), c_int(13))
            """))
        subprocess.run([
            "pixi", "run", "--manifest-path", str(manifest), "mojo", "run",
            str(consumer / "smoke.mojo"),
        ], cwd=tmp, check=True)
    print("Installed bindings, native headers, and C/Mojo calls passed.")


if __name__ == "__main__":
    main()
