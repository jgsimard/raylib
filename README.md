# Mojo raylib bindings with linear types!

Mojo bindings for raylib 6.2: all 619 functions in `raylib.h`, 35 C structs,
enum constants, and colors. Covers graphics, images, models and animation,
collisions, input, audio, and utilities. Loads native raylib at runtime.

Supports Linux x86-64 with Mojo `>=1.3.0.dev2026110405,<2`.
The exact compiler used by this checkout is recorded in `pixi.lock`.

## Quick start

With Pixi installed, run from this checkout:

```bash
pixi install --locked
pixi run example
```

This installs the pinned native raylib release and opens a window for two seconds.
See [the example](examples/raylib_window.mojo) for a complete drawing loop.
Graphics require a working display and OpenGL context.

## Updating Mojo

```bash
pixi run update_toolchain
pixi run test
```

The update task runs `pixi upgrade mojo`: it updates the Mojo requirement and
lockfile and installs the newest compatible nightly. Commit `pixi.toml` and
`pixi.lock` after checking compatibility. If the current environment cannot
start, run `pixi upgrade mojo` directly.

The package ships Mojo source and declares a minimum compiler version within
the supported major version, rather than pinning one nightly. Consumers such as
Bajo can upgrade Mojo independently without a raylib recipe change or release.
Raise the recipe's minimum only when the bindings start requiring a newer
compiler; update the supported range above at the same time.

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

`Window`, drawing sessions, `Mesh`, and `Model` are **linear types**, declared
with `Deinitable where (False, ...)`: the compiler requires explicit consumption
on every path, including errors.

- `window^.begin_drawing()` consumes the window and returns a `Frame`.
- `frame^.end()` consumes the frame and returns the window.
- `window^.close()` consumes the window and closes it.
- `frame^.begin_scissor(...)` consumes the frame and returns a `ScissorFrame`.
- `frame^.begin_3d(camera)` consumes the frame and returns a `Scene3D`.
- `scissor^.end()` and `scene^.end()` return their enclosing session.

End every frame and close the window on every path, including errors. The moved
window cannot be used while its frame owns it. Scissor and 3D modes can nest
in either order and must end in reverse order. A 3D session provides mesh/model
drawing; a 2D session provides text, rectangle, and texture drawing. Starting a
second scissor or 3D mode while the same mode is active is rejected.

`Mesh` and `Model` each have one definition, shared by the high-level bindings
and `raylib.abi`, with their C layouts preserved. Drawing borrows them; unloading
or transferring them consumes them:

```mojo
var mesh = window.sphere_mesh(1, 8, 8)
var model = library.model_from_mesh(mesh^)  # model now owns the mesh
library.unload_model(model^)
```

Use `library.unload_mesh(mesh^)` for a standalone mesh. The C-named equivalents
are `api.LoadModelFromMesh(mesh^)`, `api.UnloadMesh(mesh^)`, and
`api.UnloadModel(model^)`. A failed mesh-to-model transfer also consumes and
cleans up its source mesh. End sessions and unload GPU resources before closing
the window; linearity does not itself enforce the graphics context's lifetime.

Raw `Raylib` begin/end/close methods do not enforce the drawing protocol; avoid
mixing them with the linear session methods.

Window construction checks its native symbols up front. Drawing, input queries,
window actions, and file/path queries then use non-raising calls, so a simple
drawing loop needs no error-unwinding branches. Allocation and input validation
still raise, as do lazy symbol lookups in `Raylib` and `Library`.

`TextFont` and `Texture2D` clean up automatically. Destroy them and unload native
meshes, models, materials, and shaders before closing the window. Other ABI
structs remain copyable handles or values. Use one active window on its owning thread;
graphics context lifetime remains the caller's responsibility.

## Development

```bash
pixi run test           # compile-failure and headless native lifetime/ABI checks; requires cc
pixi run test_install   # install and import from a separate Pixi project
pixi run test_graphics  # native resources and rendered screenshot pixels
pixi run fmt
pixi publish --target-dir .pixi/dist  # build a local package
```

Graphics tests require a display and a TrueType font. Set `RAYLIB_TEST_FONT` if
`/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` is unavailable.
