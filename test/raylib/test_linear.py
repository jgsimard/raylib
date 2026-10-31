"""Check strict consumption at compile time and native ownership at runtime."""

from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import textwrap
import unittest


ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
MOJO = shutil.which("mojo") or str(ROOT / ".pixi/envs/default/bin/mojo")


class LinearBindingsTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.temp = tempfile.TemporaryDirectory(prefix="raylib-linear-")
        cls.addClassCleanup(cls.temp.cleanup)
        cls.directory = Path(cls.temp.name)
        # Window checks all its symbols before opening a native context. Export
        # unused ones as no-ops, while the fixture implements the calls under test.
        window = (ROOT / "raylib/window.mojo").read_text()
        symbol_list = window.split("var symbols:", 1)[1].split("= [", 1)[1].split("]", 1)[0]
        symbols = re.findall(r'"(\w+)"', symbol_list)
        native = (HERE / "native_ownership.c").read_text()
        implemented = set(re.findall(r"^(?:void|bool|int|Mesh|Model)\s+\**(\w+)\(", native, re.M))
        for i, symbol in enumerate(symbols):
            if symbol not in implemented:
                native += f'\nvoid stub_{i}(void) __asm__("{symbol}");\nvoid stub_{i}(void) {{}}\n'
        source = cls.directory / "native.c"
        source.write_text(native)
        cls.libraries = []
        for variant in (None, "OMIT_LOAD_MODEL", "OMIT_UNLOAD_MODEL"):
            library = cls.directory / f"{variant or 'complete'}.so"
            command = ["cc", "-shared", "-fPIC", "-I", str(ROOT / ".pixi/raylib/include")]
            if variant:
                command.append(f"-D{variant}")
            subprocess.run(command + [str(source), "-o", str(library)], check=True, capture_output=True)
            cls.libraries.append(library)

    def compile(self, source, name="case"):
        path = self.directory / f"{name}.mojo"
        path.write_text(textwrap.dedent(source))
        return subprocess.run(
            [MOJO, "build", "-I", str(ROOT), str(path), "-o", str(self.directory / name)],
            capture_output=True, text=True,
        )

    def test_native_lifetimes_and_abi(self):
        executable = self.directory / "runtime"
        build = subprocess.run(
            [MOJO, "build", "-I", str(ROOT), str(HERE / "linear_runtime.mojo"), "-o", str(executable)],
            capture_output=True, text=True,
        )
        self.assertEqual(build.returncode, 0, build.stdout + build.stderr)
        run = subprocess.run([str(executable), *map(str, self.libraries)], capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_invalid_resource_lifetimes(self):
        cases = {
            "forgot_mesh": ("var mesh = Mesh()", "Unload this mesh"),
            "double_mesh_unload": (
                "var mesh = Mesh()\napi.UnloadMesh(mesh^)\napi.UnloadMesh(mesh^)", "mesh"
            ),
            "copy_mesh": (
                "var mesh = Mesh()\nvar other = mesh\napi.UnloadMesh(mesh^)\napi.UnloadMesh(other^)", "copy"
            ),
            "forgot_model": (
                "var model = api.LoadModelFromMesh(Mesh())", "Unload this model"
            ),
            "copy_model": (
                "var model = api.LoadModelFromMesh(Mesh())\nvar other = model\napi.UnloadModel(model^)\napi.UnloadModel(other^)", "copy"
            ),
            "double_model_unload": (
                "var model = api.LoadModelFromMesh(Mesh())\napi.UnloadModel(model^)\napi.UnloadModel(model^)", "model"
            ),
            "reuse_transferred_mesh": (
                "var mesh = Mesh()\nvar model = api.LoadModelFromMesh(mesh^)\napi.UnloadMesh(mesh^)\napi.UnloadModel(model^)", "mesh"
            ),
            "exception_abandons_mesh": (
                'var mesh = Mesh()\nraise Error("failure")', "Unload this mesh"
            ),
        }
        for name, (body, diagnostic) in cases.items():
            with self.subTest(name=name):
                result = self.compile(
                    "from raylib import Mesh, Raylib\n\ndef main() raises:\n"
                    '    var api = Raylib("not-run")\n' + textwrap.indent(body, "    ") + "\n",
                    name,
                )
                self.assertNotEqual(result.returncode, 0, "invalid resource use compiled")
                self.assertIn(diagnostic, result.stderr)

    def test_invalid_session_lifetimes(self):
        cases = {
            "forgot_clip": ("var clip = frame^.begin_scissor(0, 0, 32, 32)", "scissor^.end()"),
            "end_parent_while_clipped": (
                "var clip = frame^.begin_scissor(0, 0, 32, 32)\nwindow = frame^.end()\nwindow^.close()", "frame"
            ),
            "forgot_scene": ("var scene = frame^.begin_3d(camera)", "scene^.end()"),
            "double_scene_end": (
                "var scene = frame^.begin_3d(camera)\nframe = scene^.end()\nframe = scene^.end()\nwindow = frame^.end()\nwindow^.close()", "scene"
            ),
            "nested_scissor": (
                "var clip = frame^.begin_scissor(0, 0, 32, 32)\nvar scene = clip^.begin_3d(camera)\nvar again = scene^.begin_scissor(0, 0, 32, 32)\nscene = again^.end()\nclip = scene^.end()\nframe = clip^.end()\nwindow = frame^.end()\nwindow^.close()", "Scissor mode is already active"
            ),
        }
        for name, (body, diagnostic) in cases.items():
            with self.subTest(name=name):
                result = self.compile(
                    "from raylib import Window, Camera3D, Vector3\n\ndef main() raises:\n"
                    "    var camera = Camera3D(Vector3(0,0,1), Vector3(0,0,0), Vector3(0,1,0), 45, 0)\n"
                    '    var window = Window("not-run", 64, 64, "linear", 60)\n'
                    "    var frame = window^.begin_drawing()\n" + textwrap.indent(body, "    ") + "\n",
                    name,
                )
                self.assertNotEqual(result.returncode, 0, "invalid session use compiled")
                self.assertIn(diagnostic, result.stderr)


if __name__ == "__main__":
    unittest.main()
