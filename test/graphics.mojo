"""Real OpenGL smoke test; run through pixi run test_graphics."""

from std.ffi import c_int
from std.sys.arg import argv
from std.testing import assert_equal, assert_true
from raylib import (
    BoundingBox,
    Camera3D,
    Color,
    Font,
    Image,
    Library,
    Matrix,
    TextFont,
    Texture2D,
    Vector3,
    Window,
)


def resources(window: Window, path: String, font_path: String) raises:
    var pixels: List[UInt8] = [255, 0, 0, 255]
    var texture = Texture2D(path, window, 1, 1, pixels)
    assert_true(texture.texture.id != 0)
    window.update_texture(texture.texture, pixels)
    var font = TextFont(path, font_path, 20, 1)
    assert_equal(font.font.base_size, c_int(20))
    var library = Library(path)
    var rejected_font = False
    try:
        var default_font = library.handle.get_function[Font]("GetFontDefault")()
        var missing = TextFont(
            path, font_path + ".missing", Int(default_font.base_size), 1
        )
        _ = missing.font.base_size
    except:
        rejected_font = True
    assert_true(rejected_font, "missing fonts must not become the default font")
    var rejected_shader = False
    try:
        _ = library.load_shader("invalid shader", "invalid shader")
    except:
        rejected_shader = True
    assert_true(
        rejected_shader, "invalid shaders must not become the default shader"
    )
    var shader = library.load_shader(
        (
            "#version 330\nin vec3 vertexPosition;\nuniform mat4 mvp;\n"
            "void main() { gl_Position = mvp * vec4(vertexPosition, 1.0); }"
        ),
        (
            "#version 330\nout vec4 finalColor;\n"
            "void main() { finalColor = vec4(1.0); }"
        ),
    )
    var location = library.shader_location(shader, "mvp")
    assert_true(location >= 0)
    library.set_shader_location(shader, 6, location)
    library.handle.get_function[NoneType]("UnloadShader")(shader)
    var sphere = window.sphere_mesh(1, 8, 8)
    assert_true(sphere.vertex_count > 0)
    library.unload_mesh(sphere)
    var vertices: List[Float32] = [0, 0, 0, 1, 0, 0, 0, 1, 0]
    var normals: List[Float32] = [0, 0, 1, 0, 0, 1, 0, 0, 1]
    var colors: List[UInt8] = [255, 0, 0, 255, 0, 255, 0, 255, 0, 0, 255, 255]
    var mesh = window.create_mesh(vertices, normals, colors)
    assert_true(mesh.vao_id != 0)
    var material = library.default_material()
    library.set_material_color(material, 0, Color(255, 128, 64, 255))
    library.unload_material(material)
    library.unload_mesh(mesh)


def main() raises:
    var args = argv()
    var library = Library(args[1])
    # Hidden window, still requiring a working display and OpenGL context.
    var window = Window(args[1], 160, 120, "raylib test", 60, flags=0x80)
    try:
        assert_equal(window.width(), 160)
        assert_equal(window.height(), 120)
        window.set_exit_key(0)
        _ = window.should_close()
        _ = window.is_key_down(65)
        _ = window.is_key_pressed(65)
        _ = window.mouse_position()
        _ = window.mouse_delta()
        _ = window.mouse_down()
        _ = window.mouse_pressed()
        _ = window.mouse_wheel()
        _ = window.time()
        _ = window.frame_time()
        assert_true(window.file_exists(args[2]))
        assert_true(window.directory_exists(window.directory_path(args[2])))
        assert_equal(window.file_extension(args[2]), ".ttf")
        assert_true(window.file_name(args[2]).byte_length() > 0)
        assert_true(window.parent_directory(args[2]).byte_length() > 0)
        assert_true(
            len(window.directory_files(window.directory_path(args[2]))) > 0
        )
        assert_equal(len(window.dropped_files()), 0)
        resources(window, args[1], args[2])
        var identity = Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
        var camera = Camera3D(
            Vector3(0, 0, 4), Vector3(0, 0, 0), Vector3(0, 1, 0), 45, 0
        )
        # Draw twice to exercise ownership transfer back into Window.
        for _ in range(2):
            var frame = window^.begin_drawing()
            try:
                frame.clear_background(Color(10, 20, 30, 255))
                frame.begin_3d(camera)
                frame.set_modelview(identity)
                frame.disable_backface_culling()
                frame.draw_box(
                    BoundingBox(Vector3(-1, -1, -1), Vector3(1, 1, 1)),
                    Color(255, 255, 255, 255),
                )
                frame.enable_backface_culling()
                frame.end_3d()
                frame.begin_scissor(0, 0, 160, 120)
                frame.draw_rectangle(10, 10, 30, 20, Color(90, 180, 240, 255))
                frame.end_scissor()
            except error:
                window = frame^.end()
                raise error
            window = frame^.end()
        window.screenshot(args[3])
        var image = library.handle.get_function[Image]("LoadImage")(
            args[3].as_c_string_span()
        )
        assert_equal(image.width, c_int(160))
        var color = library.handle.get_function[Color]("GetImageColor")(
            image, c_int(20), c_int(20)
        )
        library.handle.get_function[NoneType]("UnloadImage")(image)
        assert_equal(color.r, UInt8(90))
        assert_equal(color.g, UInt8(180))
        assert_equal(color.b, UInt8(240))
    except error:
        window^.close()
        raise error
    window^.close()
    print("Native graphics, resources, and screenshot pixels passed")
