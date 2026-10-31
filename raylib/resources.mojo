"""Native resource owners. A library handle retains symbols, not the GL context."""

from std.ffi import OwnedDLHandle, c_int
from std.os import abort
from .types import Font, Texture
from .window import Window


struct TextFont:
    """Own a font; release it before closing the window/context."""

    var library: OwnedDLHandle
    var font: Font

    def __init__(
        out self,
        library_path: String,
        var path: String,
        size: Int,
        texture_filter: Int,
    ) raises:
        var library = OwnedDLHandle(library_path)
        var font = library.get_function[Font]("LoadFontEx")(
            path.as_c_string_span(), c_int(size), UInt(0), c_int(0)
        )
        # raylib returns its small default font when loading fails.
        if not library.get_function[Bool]("IsFontValid")(
            font
        ) or font.base_size != c_int(size):
            raise Error("could not load font: " + path)
        library.get_function[NoneType]("SetTextureFilter")(
            font.texture, c_int(texture_filter)
        )
        self.font = font
        self.library = library^

    def __deinit__(deinit self):
        try:
            self.library.get_function[NoneType]("UnloadFont")(self.font)
        except error:
            abort(String(t"raylib font cleanup failed: {error}"))


struct Texture2D:
    """Own an RGBA8 texture; release it before closing the window/context."""

    var library: OwnedDLHandle
    var texture: Texture

    def __init__(
        out self,
        path: String,
        window: Window,
        width: Int,
        height: Int,
        pixels: ImmSpan[UInt8, _],
    ) raises:
        var library = OwnedDLHandle(path)
        self.texture = window.create_texture(width, height, pixels)
        self.library = library^

    def __deinit__(deinit self):
        try:
            self.library.get_function[NoneType]("UnloadTexture")(self.texture)
        except error:
            abort(String(t"raylib texture cleanup failed: {error}"))
