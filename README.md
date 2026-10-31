# Mojo raylib bindings

Standalone Mojo bindings for a subset of raylib 6.2: windows and input, 2D/3D
drawing, fonts, RGBA8 textures, meshes, materials, and shaders. The bindings use
only the Mojo standard library and load native raylib dynamically at runtime.
The validated target is Linux x86-64 with Mojo `1.3.0.dev2026103105`.

## Quick start

Install Pixi, then run these commands from this repository's root:

```bash
pixi install --locked
pixi run test
pixi run example
```

Pixi installs the pinned Mojo compiler and Python development dependencies.
The test and example tasks install native raylib automatically. The example
opens a window for up to two seconds and draws a blue rectangle.

Requirements:

- Linux x86-64 for the supplied environment and native installer.
- Network access on the first install to fetch dependencies and native raylib.
- A C compiler available as `cc` for the ABI test.
- A working display and OpenGL context for examples and graphics tests.

The bindings themselves depend only on Mojo's standard library. Python runs the
development checks; it is not required by applications importing the package.

## Install in another project

This project uses a Pixi build recipe to install Mojo source under
`lib/mojo`, where the consumer's compiler finds it automatically.

For a neighboring checkout, add this to your project's `pixi.toml`:

```toml
[workspace]
name = "my-raylib-app"
channels = ["https://conda.modular.com/max-nightly", "conda-forge"]
platforms = ["linux-64"]
preview = ["pixi-build"]

[dependencies]
raylib = { path = "../raylib" }
```

Run `pixi install`. Then `pixi run mojo run main.mojo` can use
`from raylib import Window, Color` without an `-I` option. The dependency brings
the tested Mojo compiler version into the consumer environment.

Once the bindings repository is hosted in Git, replace the path dependency with:

```toml
raylib = { git = "<bindings-repository-url>", branch = "main" }
```

Use the URL of this Mojo bindings repository. You can pin a `rev` instead of a
branch for reproducible builds.

For source-only use without installing the package, add the checkout's root to
Mojo's import path:

```bash
pixi run mojo run -I /absolute/path/to/raylib main.mojo /absolute/path/to/libraylib.so
```

## Native library

The Pixi package contains the bindings' source. Install native raylib separately.
In this checkout:

```bash
pixi run install_raylib
```

This downloads the official raylib 6.2 Linux x86-64 release, verifies its SHA-256,
and installs its library and headers under `.pixi/raylib` in this repository.
Pass the absolute path to `.pixi/raylib/lib/libraylib.so` when running from another
project. Native libraries from another raylib version can have incompatible ABI
layouts.

The installer supports Linux x86-64 and reuses an existing installation of the
pinned release. It requires `bash`, `curl`, `tar`, and `sha256sum`. The installer
and development tasks belong to this checkout; installing the bindings as a
dependency does not install them into the consumer project. A consumer can use
the native library installed by this checkout, or provide its own raylib 6.2
shared library.

## Usage

A minimal `main.mojo`:

```mojo
from std.sys.arg import argv
from raylib import Color, Window


def main() raises:
    var args = argv()
    if len(args) != 2:
        raise Error("usage: main <native raylib library path>")
    var window = Window(args[1], 640, 360, "Mojo raylib", 60)
    try:
        while not window.should_close():
            var frame = window^.begin_drawing()
            try:
                frame.clear_background(Color(24, 27, 33, 255))
                frame.draw_rectangle(220, 130, 200, 100, Color(90, 180, 240, 255))
            except error:
                window = frame^.end()
                raise error
            window = frame^.end()
    except error:
        window^.close()
        raise error
    window^.close()
```

Run it with `pixi run mojo run main.mojo /absolute/path/to/libraylib.so`.
A working display and OpenGL context are required. For the included two-second
window example, run `pixi run example` from this checkout.

## Public API

Import public types directly from `raylib`:

```mojo
from raylib import Color, Frame, Library, TextFont, Texture2D, Window
```

| Type | Purpose |
| --- | --- |
| `Window` | Open and close the native window; query input, timing, clipboard, paths, directory contents, and dropped files; resize, toggle fullscreen, and take screenshots; upload meshes and textures. |
| `Frame` | Begin and end drawing; clear the background; draw rectangles, text, textures, meshes, and bounding boxes; control scissor mode, 3D mode, modelview, and backface culling. |
| `Library` | Load shaders, query and set shader locations, create default materials, set material colors, and explicitly unload meshes and materials. |
| `TextFont` | Own a font loaded from a caller-supplied path, with a requested size and texture filter. Access its non-owning ABI value through `.font`. |
| `Texture2D` | Own an uploaded RGBA8 texture. Access its non-owning ABI value through `.texture`. |

The exported C ABI layouts are `Color`, `Vector2`, `Vector3`, `Camera3D`, `Matrix`,
`Rectangle`, `FilePathList`, `BoundingBox`, `Image`, `Texture`, `Font`, `Shader`,
`MaterialMap`, `Material`, and `Mesh`. These describe native values and handles;
constructing or copying them does not allocate or duplicate native resources.

`Texture` is the non-owning native layout; `Texture2D` is the owning wrapper.
Texture creation and updates expect exactly `width * height * 4` bytes in RGBA8
format. `Window.create_mesh()` accepts triangle vertices, matching normals, and
four color bytes per vertex. `Matrix` follows raylib's native field order.

The caller supplies the native library path, font paths, filtering, camera
matrices, and sphere tessellation settings. The package embeds no application
assets or default native library path. Input keys, window flags, filters, and
shader/material slots use native raylib numeric values.

`Library.handle` exposes the dynamic library handle for native operations not yet
wrapped by the package. For example, a shader loaded through `Library` can be
released while the graphics context is still alive:

```mojo
library.handle.get_function[NoneType]("UnloadShader")(shader)
```

## Validation and development

```bash
pixi run test           # display-free C ABI checks and isolated Mojo compilation
pixi run test_install   # build/install in a temporary consumer; import without -I
pixi run test_graphics  # hidden window, native resources, screenshot pixel checks
pixi run fmt
```

`test` requires a C compiler (`cc`). It checks the size, alignment, every field
offset, and C argument/return behavior of all 15 exported ABI structs against the
pinned native header. It copies only the `raylib` package into a temporary directory
and compiles the example and graphics test there, independently of this checkout's
import path. Missing native headers fail the test.

`test_graphics` requires a working display/OpenGL context and a TrueType font.
It defaults to `/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf`; set
`RAYLIB_TEST_FONT` to another `.ttf` path if needed. It checks input and filesystem
calls, font and texture ownership, shader compilation and failure handling,
mesh/material creation and unloading, repeated
drawing sessions, and the actual rendered rectangle pixels in a screenshot.

`test_install` creates an unrelated temporary Pixi workspace, builds and installs
this checkout as a path dependency, and runs a public import without `-I`. It
requires access to Pixi's dependency channels or a populated local cache.
`test_raylib` is an alias for `test`.

To build a local Conda artifact without uploading it:

```bash
pixi publish --target-dir .pixi/dist
```

The resulting `.conda` package contains Mojo source under `lib/mojo/raylib` and
declares the tested compiler as a runtime dependency. Source distribution lets
the consumer compile the bindings in its own environment.

## Repository layout

| Path | Contents |
| --- | --- |
| `raylib/__init__.mojo` | Public exports. |
| `raylib/types.mojo` | Non-owning C ABI layouts and opaque native addresses. |
| `raylib/window.mojo` | Window ownership, input, drawing sessions, mesh and texture uploads. |
| `raylib/library.mojo` | Material, shader, and mesh operations. |
| `raylib/resources.mojo` | Owning font and texture wrappers. |
| `examples/raylib_window.mojo` | Standalone two-second window example. |
| `test/raylib/test_bindings.py` | Header-based ABI validation and isolated compilation. |
| `test/graphics.mojo`, `test/graphics.py` | Native graphics and resource checks. |
| `test/install.py` | External consumer installation check. |
| `install_raylib.sh` | Checksum-pinned native raylib installer. |
| `pixi.toml`, `pixi.lock`, `recipe.yaml` | Development environment, locked dependencies, and package recipe. |

## Resource ownership

`Window.begin_drawing()` transfers the window into a `Frame`; `Frame.end()` returns
it. End every frame and call `Window.close()` explicitly, including on error
paths. Raylib's native window/context is global: use one active window and make
graphics calls on its owning thread.

Destroy `TextFont`, `Texture2D`, and uploaded meshes, materials, and shaders before
closing the window. A dynamic library handle retains cleanup symbols, not the
OpenGL context. ABI structs are copyable, non-owning handles; unload each native
resource once. `TextFont` and `Texture2D` release their native resources when their
Mojo owners are destroyed; keep their lifetime within the active graphics context.
Native shader location and material map indices must be valid raylib indices.

## Limitations

This is a partial binding, not the complete raylib API. The Pixi environment,
native installer, and ABI checks currently target Linux x86-64. Other platforms
require their own native library provisioning and ABI validation.

Graphics context lifetime is managed explicitly. Resource wrappers retain the
native library, but do not prevent the window from closing before their cleanup.
The package does not track nested drawing modes, validate all native numeric
indices, or manage application scene/resource collections.
