"""Validate the extractable package against raylib's C ABI without a display."""

import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


# Mojo field, C field, scalar type. Nested layouts are expanded into leaf fields
# so every offset and every component of a struct argument/return is exercised.
LAYOUTS = {
    "Color": [(n, n, "UInt8") for n in ("r", "g", "b", "a")],
    "Vector2": [(n, n, "Float32") for n in ("x", "y")],
    "Vector3": [(n, n, "Float32") for n in ("x", "y", "z")],
    "Camera3D": [
        ("position", "position", "Vector3"),
        ("target", "target", "Vector3"),
        ("up", "up", "Vector3"),
        ("fovy", "fovy", "Float32"),
        ("projection", "projection", "c_int"),
    ],
    "Matrix": [(f"m{n}", f"m{n}", "Float32") for n in range(16)],
    "Rectangle": [(n, n, "Float32") for n in ("x", "y", "width", "height")],
    "FilePathList": [("count", "count", "c_uint"), ("paths", "paths", "UInt")],
    "BoundingBox": [("minimum", "min", "Vector3"), ("maximum", "max", "Vector3")],
    "Image": [("data", "data", "UInt")] + [
        (n, n, "c_int") for n in ("width", "height", "mipmaps", "format")
    ],
    "Texture": [("id", "id", "c_uint")] + [
        (n, n, "c_int") for n in ("width", "height", "mipmaps", "format")
    ],
    "Font": [
        ("base_size", "baseSize", "c_int"),
        ("glyph_count", "glyphCount", "c_int"),
        ("glyph_padding", "glyphPadding", "c_int"),
        ("texture", "texture", "Texture"),
        ("rectangles", "recs", "UInt"),
        ("glyphs", "glyphs", "UInt"),
    ],
    "Shader": [("id", "id", "c_uint"), ("locs", "locs", "UInt")],
    "MaterialMap": [
        ("texture", "texture", "Texture"),
        ("color", "color", "Color"),
        ("value", "value", "Float32"),
    ],
    "Material": [
        ("shader", "shader", "Shader"),
        ("maps", "maps", "UInt"),
    ] + [(f"p{n}", f"params[{n}]", "Float32") for n in range(4)],
    "Mesh": [
        ("vertex_count", "vertexCount", "c_int"),
        ("triangle_count", "triangleCount", "c_int"),
    ] + [(n, n, "UInt") for n in (
        "vertices", "texcoords", "texcoords2", "normals", "tangents", "colors", "indices"
    )] + [
        ("bone_count", "boneCount", "c_int"),
        ("bone_indices", "boneIndices", "UInt"),
        ("bone_weights", "boneWeights", "UInt"),
        ("anim_vertices", "animVertices", "UInt"),
        ("anim_normals", "animNormals", "UInt"),
        ("vao_id", "vaoId", "c_uint"),
        ("vbo_id", "vboId", "UInt"),
    ],
}


def leaves(name, mojo_prefix="", c_prefix=""):
    for mojo_field, c_field, scalar in LAYOUTS[name]:
        mojo_field = mojo_prefix + mojo_field
        c_field = c_prefix + c_field
        if scalar in LAYOUTS:
            yield from leaves(scalar, mojo_field + ".", c_field + ".")
        else:
            yield mojo_field, c_field, scalar


class BindingTests(unittest.TestCase):
    def test_standalone_package_matches_native_abi(self):
        root = Path(__file__).resolve().parents[2]
        include = root / ".pixi/raylib/include"
        self.assertTrue(
            (include / "raylib.h").exists(),
            "install the pinned headers with pixi run install_raylib",
        )
        compiler = shutil.which("mojo") or str(root / ".pixi/envs/default/bin/mojo")
        # mojo needs its companion executables on PATH when run outside Pixi.
        env = dict(os.environ, PATH=f"{Path(compiler).parent}:{os.environ['PATH']}")
        with tempfile.TemporaryDirectory(prefix="raylib standalone ") as tmp:
            directory = Path(tmp)
            shutil.copytree(root / "raylib", directory / "raylib")
            shutil.copy(root / "examples/raylib_window.mojo", directory / "example.mojo")
            shutil.copy(root / "test/graphics.mojo", directory / "graphics.mojo")
            c = ['#include <raylib.h>', '#include <stddef.h>', '#include <stdint.h>']
            mojo = [
                'from std.ffi import OwnedDLHandle, c_int, c_uint',
                'from std.memory import Pointer',
                'from std.sys import size_of, align_of',
                'from std.sys.arg import argv',
                'from std.testing import assert_equal',
                'from raylib import ' + ', '.join(LAYOUTS),
                '', 'def main() raises:',
                '    var library = OwnedDLHandle(argv()[1])',
            ]
            for name in LAYOUTS:
                c.extend([
                    f'size_t size_{name}(void) {{ return sizeof({name}); }}',
                    f'size_t align_{name}(void) {{ return _Alignof({name}); }}',
                    f'{name} make_{name}(void) {{', f'    {name} v = {{0}};',
                ])
                checks = []
                values = []
                for index, (mojo_field, c_field, scalar) in enumerate(leaves(name), 1):
                    value = str(4096 + index * 16) if scalar == "UInt" else (
                        f"{index}.25" if scalar == "Float32" else str(index)
                    )
                    c_value = f'(void *)(uintptr_t){value}' if scalar == "UInt" else value
                    c.append(f'    v.{c_field} = {c_value};')
                    checks.append(f'v.{c_field} == {c_value}')
                    values.append((mojo_field, c_field, scalar, value))
                c.extend([
                    '    return v;', '}',
                    f'int check_{name}({name} v) {{ return ' + ' && '.join(checks) + '; }',
                ])
                mojo.extend([
                    f'    assert_equal(size_of[{name}](), Int(library.get_function[UInt]("size_{name}")()))',
                    f'    assert_equal(align_of[{name}](), Int(library.get_function[UInt]("align_{name}")()))',
                    f'    var value_{name} = library.get_function[{name}]("make_{name}")()',
                ])
                for index, (mojo_field, c_field, scalar, value) in enumerate(values):
                    symbol = f'offset_{name}_{index}'
                    c.append(f'size_t {symbol}(void) {{ return offsetof({name}, {c_field}); }}')
                    mojo.extend([
                        f'    assert_equal(value_{name}.{mojo_field}, {scalar}({value}))',
                        f'    assert_equal(Int(Pointer(to=value_{name}.{mojo_field})) - Int(Pointer(to=value_{name})), Int(library.get_function[UInt]("{symbol}")()))',
                    ])
                mojo.append(f'    assert_equal(library.get_function[c_int]("check_{name}")(value_{name}), c_int(1))')
            (directory / "abi.c").write_text("\n".join(c) + "\n")
            (directory / "check.mojo").write_text("\n".join(mojo) + "\n")
            commands = [
                ["cc", "-std=c11", "-Wall", "-Werror", "-shared", "-fPIC", f"-I{include}", "abi.c", "-o", "abi.so"],
                [compiler, "run", "-I", tmp, "check.mojo", str(directory / "abi.so")],
                [compiler, "build", "-I", tmp, "example.mojo", "-o", "example"],
                [compiler, "build", "-I", tmp, "graphics.mojo", "-o", "graphics"],
            ]
            for command in commands:
                result = subprocess.run(command, cwd=tmp, env=env, capture_output=True, text=True, timeout=120)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
