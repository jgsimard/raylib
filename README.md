# Mojo raylib bindings with linear types!

Mojo bindings for a subset of raylib 6.2: windows, input, 2D/3D drawing, fonts,
textures, meshes, materials, and shaders. Uses Mojo's standard library and loads
native raylib at runtime.

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
platforms = ["linux-64"]
preview = ["pixi-build"]

[dependencies]
raylib = { git = "https://github.com/jgsimard/raylib.git", branch = "main" }
```

Run `pixi install`, then import without an `-I` option:

```mojo
from raylib import Color, Window, Frame, Library, TextFont, Texture2D
```

Native raylib is installed separately. Run `pixi run install_raylib` in this
checkout, then pass the absolute path to `.pixi/raylib/lib/libraylib.so` when
constructing a `Window` in your application.

## Linear types and ownership

`Window` and `Frame` are **linear types**: ownership moves, and the compiler
requires explicit consumption instead of implicit destruction.

- `window^.begin_drawing()` consumes the window and returns a `Frame`.
- `frame^.end()` consumes the frame and returns the window.
- `window^.close()` consumes the window and closes it.

End every frame and close the window on every path, including errors. The moved
window cannot be used while its frame owns it.

`TextFont` and `Texture2D` clean up automatically. Destroy them and unload native
meshes, materials, and shaders before closing the window. Raw ABI structs are
copyable, non-owning handles. Use one active window on its owning thread;
graphics context lifetime remains the caller's responsibility.

## Development

```bash
pixi run test           # C ABI checks for all 15 structs; requires cc
pixi run test_install   # install and import from a separate Pixi project
pixi run test_graphics  # native resources and rendered screenshot pixels
pixi run fmt
pixi publish --target-dir .pixi/dist  # build a local package
```

Graphics tests require a display and a TrueType font. Set `RAYLIB_TEST_FONT` if
`/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf` is unavailable.
