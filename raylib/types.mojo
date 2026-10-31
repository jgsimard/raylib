"""Raylib 6.2 C layouts. Mesh and Model require explicit consumption."""

from std.ffi import OwnedDLHandle, c_int, c_uint


@fieldwise_init
struct Color(ImplicitlyCopyable, RegisterPassable):
    """Raylib Color: four unsigned bytes, passed by value."""

    var r: UInt8
    var g: UInt8
    var b: UInt8
    var a: UInt8


@fieldwise_init
struct Vector2(ImplicitlyCopyable, RegisterPassable):
    """Raylib Vector2: two C floats, passed by value."""

    var x: Float32
    var y: Float32


@fieldwise_init
struct Vector3(ImplicitlyCopyable, RegisterPassable):
    var x: Float32
    var y: Float32
    var z: Float32


@fieldwise_init
struct Camera3D(ImplicitlyCopyable, RegisterPassable):
    var position: Vector3
    var target: Vector3
    var up: Vector3
    var fovy: Float32
    var projection: c_int


@fieldwise_init
struct Matrix(ImplicitlyCopyable, RegisterPassable):
    # raylib stores its column-numbered fields in row order in the C struct.
    var m0: Float32
    var m4: Float32
    var m8: Float32
    var m12: Float32
    var m1: Float32
    var m5: Float32
    var m9: Float32
    var m13: Float32
    var m2: Float32
    var m6: Float32
    var m10: Float32
    var m14: Float32
    var m3: Float32
    var m7: Float32
    var m11: Float32
    var m15: Float32


@fieldwise_init
struct Rectangle(ImplicitlyCopyable, RegisterPassable):
    var x: Float32
    var y: Float32
    var width: Float32
    var height: Float32


@fieldwise_init
struct FilePathList(ImplicitlyCopyable, RegisterPassable):
    var count: c_uint
    var paths: UInt


@fieldwise_init
struct BoundingBox(ImplicitlyCopyable, RegisterPassable):
    var minimum: Vector3
    var maximum: Vector3


@fieldwise_init
struct Image(ImplicitlyCopyable, RegisterPassable):
    var data: UInt
    var width: c_int
    var height: c_int
    var mipmaps: c_int
    var format: c_int


@fieldwise_init
struct Texture(ImplicitlyCopyable, RegisterPassable):
    var id: c_uint
    var width: c_int
    var height: c_int
    var mipmaps: c_int
    var format: c_int


@fieldwise_init
struct Font(ImplicitlyCopyable, RegisterPassable):
    """Raylib Font ABI; glyph data remains owned by TextFont."""

    var base_size: c_int
    var glyph_count: c_int
    var glyph_padding: c_int
    var texture: Texture
    var rectangles: UInt
    var glyphs: UInt


@fieldwise_init
struct Shader(ImplicitlyCopyable, RegisterPassable):
    var id: c_uint
    var locs: UInt


@fieldwise_init
struct MaterialMap(ImplicitlyCopyable, RegisterPassable):
    var texture: Texture
    var color: Color
    var value: Float32


@fieldwise_init
struct Material(ImplicitlyCopyable, RegisterPassable):
    var shader: Shader
    var maps: UInt
    var p0: Float32
    var p1: Float32
    var p2: Float32
    var p3: Float32


@fieldwise_init
struct Mesh(
    Deinitable where (
        False,
        "Unload this mesh or transfer it into a model",
    ),
    Movable,
    RegisterPassable,
):
    """Raylib 6.2 mesh ABI; native-size integers hold opaque C addresses."""

    var vertex_count: c_int
    var triangle_count: c_int
    var vertices: UInt
    var texcoords: UInt
    var texcoords2: UInt
    var normals: UInt
    var tangents: UInt
    var colors: UInt
    var indices: UInt
    var bone_count: c_int
    var bone_indices: UInt
    var bone_weights: UInt
    var anim_vertices: UInt
    var anim_normals: UInt
    var vao_id: c_uint
    var vbo_id: UInt

    def __init__(out self):
        self.vertex_count = 0
        self.triangle_count = 0
        self.vertices = 0
        self.texcoords = 0
        self.texcoords2 = 0
        self.normals = 0
        self.tangents = 0
        self.colors = 0
        self.indices = 0
        self.bone_count = 0
        self.bone_indices = 0
        self.bone_weights = 0
        self.anim_vertices = 0
        self.anim_normals = 0
        self.vao_id = 0
        self.vbo_id = 0

    def unload(deinit self, library: OwnedDLHandle):
        """Consume this mesh and free its CPU/GPU allocations."""
        library.borrow().call["UnloadMesh"](self)

    def into_model(deinit self, library: OwnedDLHandle) raises -> Model:
        """Transfer the mesh's allocations to a model without unloading them."""
        for symbol in ["LoadModelFromMesh", "UnloadModel"]:
            if not library.check_symbol(symbol):
                self^.unload(library)
                raise Error("raylib is missing symbol: " + symbol)
        return library.borrow().call["LoadModelFromMesh", Model](self)


@fieldwise_init
struct ModelSkeleton(ImplicitlyCopyable, RegisterPassable):
    var bone_count: c_uint
    var bones: UInt
    var bind_pose: UInt


@fieldwise_init
struct Model(
    Deinitable where (False, "Unload this model to release its meshes"),
    Movable,
    RegisterPassable,
):
    var transform: Matrix
    var mesh_count: c_int
    var material_count: c_int
    var meshes: UInt
    var materials: UInt
    var mesh_material: UInt
    var skeleton: ModelSkeleton
    var current_pose: UInt
    var bone_matrices: UInt

    def unload(deinit self, library: OwnedDLHandle):
        """Consume this model and release its native allocations."""
        library.borrow().call["UnloadModel"](self)
