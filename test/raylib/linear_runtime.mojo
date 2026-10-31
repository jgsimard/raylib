"""Exercise linear sessions and native resource transfers without a display."""

from std.ffi import OwnedDLHandle, c_int
from std.sys.arg import argv
from std.sys import size_of
from std.testing import assert_equal, assert_true
from raylib import (
    Window,
    Library,
    Raylib,
    Mesh,
    Model,
    Material,
    Shader,
    Matrix,
    Camera3D,
    Vector3,
    Color,
    BoundingBox,
)
from raylib.abi import Mesh as ABIMesh, Model as ABIModel


def camera() -> Camera3D:
    return Camera3D(Vector3(0, 0, 1), Vector3(0, 0, 0), Vector3(0, 1, 0), 45, 0)


def identity() -> Matrix:
    return Matrix(1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)


def check_events(api: OwnedDLHandle, expected: List[Int]) raises:
    assert_equal(
        Int(api.borrow().call["TestEventCount", c_int]()), len(expected)
    )
    for i in range(len(expected)):
        assert_equal(
            Int(api.borrow().call["TestEvent", c_int](c_int(i))), expected[i]
        )
    assert_equal(api.borrow().call["TestOutstanding", c_int](), c_int(0))


def test_sessions(path: String, inspect: OwnedDLHandle) raises:
    inspect.borrow().call["TestReset"]()
    var window = Window(path, 64, 64, "linear", 60)
    try:
        var frame = window^.begin_drawing()
        var clip = frame^.begin_scissor(0, 0, 32, 32)
        try:
            clip.draw_rectangle(0, 0, 16, 16, Color(42, 0, 0, 255))
        except error:
            frame = clip^.end()
            window = frame^.end()
            raise error
        var scene = clip^.begin_3d(camera())
        try:
            scene.draw_box(
                BoundingBox(Vector3(0, 0, 0), Vector3(1, 1, 1)),
                Color(42, 0, 0, 255),
            )
        except error:
            clip = scene^.end()
            frame = clip^.end()
            window = frame^.end()
            raise error
        clip = scene^.end()
        frame = clip^.end()
        var scene2 = frame^.begin_3d(camera())
        var clip2 = scene2^.begin_scissor(0, 0, 32, 32)
        # Exercise explicit unwinding with both modes active.
        try:
            raise Error("intentional drawing failure")
        except:
            scene2 = clip2^.end()
            frame = scene2^.end()
        window = frame^.end()
    except error:
        window^.close()
        raise error
    window^.close()
    check_events(inspect, [1, 3, 7, 5, 14, 6, 4, 5, 3, 4, 6, 2, 13])


def test_resources(path: String, inspect: OwnedDLHandle) raises:
    inspect.borrow().call["TestReset"]()
    var api = Raylib(path)
    var library = Library(path)
    var window = Window(path, 64, 64, "linear", 60)
    try:
        var mesh = window.sphere_mesh(1, 8, 8)
        var frame = window^.begin_drawing()
        var scene = frame^.begin_3d(camera())
        try:
            scene.draw_mesh(
                mesh, Material(Shader(0, 0), 0, 0, 0, 0, 0), identity()
            )
        except error:
            frame = scene^.end()
            window = frame^.end()
            library.unload_mesh(mesh^)
            raise error
        frame = scene^.end()
        window = frame^.end()
        var model = api.LoadModelFromMesh(mesh^)
        frame = window^.begin_drawing()
        var scene2 = frame^.begin_3d(camera())
        try:
            assert_equal(model.skeleton.bone_count, 23)
            assert_equal(model.current_pose, UInt(0x1234))
            assert_equal(model.bone_matrices, UInt(0x5678))
            scene2.draw_model(model, Vector3(0, 0, 0), 1, Color(42, 0, 0, 255))
        except error:
            frame = scene2^.end()
            window = frame^.end()
            api.UnloadModel(model^)
            raise error
        frame = scene2^.end()
        window = frame^.end()
        api.UnloadModel(model^)
    except error:
        window^.close()
        raise error
    window^.close()
    check_events(inspect, [1, 5, 8, 6, 2, 11, 1, 5, 9, 6, 2, 10, 12, 13])


def test_allocations(path: String, inspect: OwnedDLHandle) raises:
    inspect.borrow().call["TestReset"]()
    var library = Library(path)
    var api = Raylib(path)
    var window = Window(path, 64, 64, "linear", 60)
    try:
        var vertices: List[Float32] = [1, 0, 0, 0, 1, 0, 0, 0, 1]
        var normals: List[Float32] = [0, 0, 1, 0, 0, 1, 0, 0, 1]
        var colors = List[UInt8](length=12, fill=42)
        for i in range(3):
            inspect.borrow().call["TestFailAllocAfter"](c_int(i))
            var failed = False
            try:
                var mesh = window.create_mesh(vertices, normals, colors)
                library.unload_mesh(mesh^)
            except:
                failed = True
            assert_true(failed)
            assert_equal(
                inspect.borrow().call["TestOutstanding", c_int](), c_int(0)
            )
        var mesh = window.create_mesh(vertices, normals, colors)
        api.UnloadMesh(mesh^)
        var sphere = window.sphere_mesh(1, 8, 8)
        var model = library.model_from_mesh(sphere^)
        library.unload_model(model^)
        var sphere2 = window.sphere_mesh(1, 8, 8)
        library.unload_mesh(sphere2^)
    except error:
        window^.close()
        raise error
    window^.close()
    check_events(inspect, [10, 10, 10, 10, 11, 10, 12, 10, 13])


def test_transfer_failure(path: String) raises:
    var inspect = OwnedDLHandle(path)
    var api = Raylib(path)
    var window = Window(path, 64, 64, "linear", 60)
    var failed = False
    try:
        var mesh = window.sphere_mesh(1, 8, 8)
        var model = api.LoadModelFromMesh(mesh^)
        api.UnloadModel(model^)
    except:
        failed = True
    window^.close()
    assert_true(failed)
    check_events(inspect, [10, 13])


def main() raises:
    comptime assert Mesh == ABIMesh
    comptime assert Model == ABIModel
    var args = argv()
    var inspect = OwnedDLHandle(args[1])
    assert_equal(
        size_of[Mesh](), Int(inspect.borrow().call["TestMeshSize", c_int]())
    )
    assert_equal(
        size_of[Model](), Int(inspect.borrow().call["TestModelSize", c_int]())
    )
    test_sessions(args[1], inspect)
    test_resources(args[1], inspect)
    test_allocations(args[1], inspect)
    test_transfer_failure(args[2])
    test_transfer_failure(args[3])
