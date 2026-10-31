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
                stub = f'\nvoid stub_{i}(void) __asm__("{symbol}");\nvoid stub_{i}(void) {{}}\n'
                if symbol == "SetConfigFlags":
                    stub = "\n#ifndef OMIT_WINDOW_SYMBOL\n" + stub + "#endif\n"
                native += stub
        source = cls.directory / "native.c"
        source.write_text(native)
        cls.libraries = []
        for variant in (None, "OMIT_LOAD_MODEL", "OMIT_UNLOAD_MODEL", "OMIT_WINDOW_SYMBOL"):
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
        run = subprocess.run([str(executable), *map(str, self.libraries[:3])], capture_output=True, text=True)
        self.assertEqual(run.returncode, 0, run.stdout + run.stderr)

    def test_nonraising_window_and_drawing(self):
        # A linear Window cannot cross a throwing call without cleanup. This
        # helper deliberately has no raises annotation or error branches.
        result = self.compile('''\
            from raylib import (
                Window, Camera3D, Vector3, Color, BoundingBox, Material, Shader,
                Matrix, Font, Texture, Model, Raylib,
            )

            def exercise(var window: Window, model: Model) -> Window:
                _ = window.should_close()
                _ = window.is_key_down(0)
                _ = window.is_key_pressed(0)
                window.set_exit_key(0)
                _ = window.mouse_position()
                _ = window.mouse_pressed()
                _ = window.mouse_wheel()
                _ = window.time()
                _ = window.clipboard_text()
                _ = window.directory_exists(".")
                _ = window.file_exists("file")
                _ = window.directory_path("file")
                _ = window.parent_directory(".")
                _ = window.file_name("file")
                _ = window.file_extension("file")
                _ = window.directory_files(".")
                _ = window.dropped_files()
                window.toggle_fullscreen()
                _ = window.frame_time()
                _ = window.mouse_delta()
                _ = window.mouse_down()
                _ = window.width()
                _ = window.height()
                window.resize(64, 64)
                window.screenshot("frame.png")
                var mesh = window.sphere_mesh(1, 8, 8)
                var frame = window^.begin_drawing()
                frame.clear_background(Color(42, 0, 0, 255))
                var clip = frame^.begin_scissor(0, 0, 32, 32)
                clip.draw_rectangle(0, 0, 16, 16, Color(42, 0, 0, 255))
                clip.draw_texture(Texture(0, 1, 1, 1, 7), 1, 1)
                clip.draw_text_ex(
                    Font(1, 0, 0, Texture(0, 1, 1, 1, 7), 0, 0),
                    "label", 0, 0, 12, Color(42, 0, 0, 255),
                )
                var scene = clip^.begin_3d(Camera3D(
                    Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), 45, 0,
                ))
                var identity = Matrix(1,0,0,0, 0,1,0,0, 0,0,1,0, 0,0,0,1)
                scene.set_modelview(identity)
                scene.disable_backface_culling()
                scene.enable_backface_culling()
                scene.draw_mesh(mesh, Material(Shader(0,0), 0,0,0,0,0), identity)
                scene.draw_model(model, Vector3(0,0,0), 1, Color(42,0,0,255))
                scene.draw_box(
                    BoundingBox(Vector3(0,0,0), Vector3(1,1,1)), Color(42,0,0,255),
                )
                clip = scene^.end()
                frame = clip^.end()
                window = frame^.end()
                mesh^.unload(window.library)
                return window^

            def main() raises:
                var api = Raylib("not-run")
                var model = api.LoadModel("not-run")
                try:
                    var window = Window("not-run", 64, 64, "linear", 60)
                    window = exercise(window^, model)
                    window^.close()
                except error:
                    api.UnloadModel(model^)
                    raise error
                api.UnloadModel(model^)
        ''', "nonraising")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_missing_window_symbol_raises_before_initialization(self):
        result = self.compile('''\
            from std.sys.arg import argv
            from std.testing import assert_true
            from raylib import Window

            def main() raises:
                var failed = False
                try:
                    var window = Window(argv()[1], 64, 64, "linear", 60)
                    window^.close()
                except:
                    failed = True
                assert_true(failed)
        ''', "missing_window_symbol")
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        run = subprocess.run(
            [str(self.directory / "missing_window_symbol"), str(self.libraries[3])],
            capture_output=True, text=True,
        )
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
