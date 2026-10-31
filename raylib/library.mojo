"""Resource operations independent of any window or application scene."""

from std.ffi import OwnedDLHandle, c_int
from std.memory import Pointer
from .types import Color, Material, MaterialMap, Mesh, Shader


struct Library:
    """Retain native cleanup symbols; callers must keep the GL context alive."""

    var handle: OwnedDLHandle

    def __init__(out self, path: String) raises:
        self.handle = OwnedDLHandle(path)

    def default_material(self) raises -> Material:
        return self.handle.get_function[Material]("LoadMaterialDefault")()

    def load_shader(
        self, var vertex_source: String, var fragment_source: String
    ) raises -> Shader:
        var shader = self.handle.get_function[Shader]("LoadShaderFromMemory")(
            vertex_source.as_c_string_span(), fragment_source.as_c_string_span()
        )
        if not self.handle.get_function[Bool]("IsShaderValid")(shader):
            raise Error("raylib shader failed to compile")
        return shader

    def shader_location(self, shader: Shader, var name: String) raises -> Int:
        return Int(
            self.handle.get_function[c_int]("GetShaderLocation")(
                shader, name.as_c_string_span()
            )
        )

    def set_shader_location(self, shader: Shader, slot: Int, location: Int):
        """Set a raylib shader location slot; slot must be a valid native index.
        """
        var locations = Pointer[c_int, MutUntrackedOrigin](
            unsafe_from_address=Int(shader.locs)
        )
        locations[unsafe_offset=slot] = c_int(location)

    def set_material_color(
        self, material: Material, map_index: Int, color: Color
    ):
        """Set a material map color; map_index must be a valid native index."""
        var maps = Pointer[MaterialMap, MutUntrackedOrigin](
            unsafe_from_address=Int(material.maps)
        )
        maps[unsafe_offset=map_index].color = color

    def unload_mesh(self, mesh: Mesh) raises:
        self.handle.get_function[NoneType]("UnloadMesh")(mesh)

    def unload_material(self, material: Material) raises:
        self.handle.get_function[NoneType]("UnloadMaterial")(material)
