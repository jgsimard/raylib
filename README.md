# Mojo raylib bindings with linear types!

Mojo bindings for raylib 6.2: all 619 functions in `raylib.h`, 35 C structs,
enum constants, and colors. Covers graphics, images, models and animation,
collisions, input, audio, and utilities. Loads native raylib at runtime.

Supports Linux x86-64 with Mojo `1.3.0.dev2026103105`.

## Quick start

With Pixi installed, run from this checkout:

```bash
pixi install --locked
pixi run example
```

This installs the pinned native raylib release and opens a window for two seconds.
See [the example](examples/raylib_window.mojo) for a complete drawing loop with
error handling. Graphics require a working display and OpenGL context.

## Use in another project

Add to your project's `pixi.toml`:

```toml
[workspace]
name = "my-raylib-app"
channels = ["https://conda.modular.com/max-nightly", "conda-forge"]
platforms = [{ platform = "linux-64", glibc = "2.38" }]
preview = ["pixi-build"]

[dependencies]
raylib = { git = "https://github.com/jgsimard/raylib.git", branch = "main" }
```

Run `pixi install`, then import without an `-I` option:

```mojo
from raylib import Color, Window, Frame, Library, TextFont, Texture2D
```

The package also installs the checksum-verified native raylib 6.2 shared library
in `$CONDA_PREFIX/lib` and its headers in `$CONDA_PREFIX/include`. Applications do
not need a native installer. Pass `$CONDA_PREFIX/lib/libraylib.so` when constructing
a `Window` (or supply a custom native library path). The official Linux binary
requires glibc 2.38 or later, which the package declares as a runtime requirement.

The checkout's `install_raylib.sh` remains a development helper for source-based
examples and binding generation; it is not needed by consumers of the package.

## Full C API

`Raylib` exposes raylib's original C function names:

```mojo
from raylib import Raylib, Vector2

var api = Raylib(library_path)
var hit = api.CheckCollisionCircles(Vector2(0, 0), 2, Vector2(1, 0), 2)
```

Strings have `String` overloads; `const char*` results from these overloads are
copied into Mojo strings. Raw pointers, output parameters, and callbacks use
`UInt` addresses (`0` is NULL). C arrays in structs use fixed tuples. Raw resources
require matching native unload calls. The C `Texture2D` alias is available from
`raylib.abi`; the package-level `Texture2D` remains the owning wrapper.

`TextFormat` and `TraceLog` accept C format arguments: use `c_int` for integers,
`Float64` for floating-point values, and C string pointers for `%s`.
Constants use namespaces, such as `KEY.SPACE`, `PIXELFORMAT.UNCOMPRESSED_GRAYSCALE`,
`SHADER.LOC_MATRIX_MVP`, and `TEXTURE.FILTER_BILINEAR`.

## Linear types and ownership

`Window` and `Frame` are **linear types**: ownership moves, and the compiler
requires explicit consumption instead of implicit destruction.

- `window^.begin_drawing()` consumes the window and returns a `Frame`.
- `frame^.end()` consumes the frame and returns the window.
- `window^.close()` consumes the window and closes it.

End every frame and close the window on every path, including errors. The moved
window cannot be used while its frame owns it.
Raw `Raylib` methods do not enforce this protocol; use the linear owners for
window/frame lifetime and avoid mixing their lifecycle calls with raw calls.

`TextFont` and `Texture2D` clean up automatically. Destroy them and unload native
meshes, materials, and shaders before closing the window. Raw ABI structs are
copyable, non-owning handles. Use one active window on its owning thread;
graphics context lifetime remains the caller's responsibility.

## Development

```bash
pixi run test           # complete API, constants, and struct ABI checks; requires cc
pixi run test_install   # install and import from a separate Pixi project
pixi run test_graphics  # native resources and rendered screenshot pixels
pixi run fmt
pixi publish --target-dir .pixi/dist  # build a local package
```

Graphics tests require a display and a TrueType font. Set `RAYLIB_TEST_FONT` if
`/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` is unavailable.
