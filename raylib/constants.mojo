from .types import Color

comptime RAYLIB_VERSION_MAJOR = 6
comptime RAYLIB_VERSION_MINOR = 2
comptime RAYLIB_VERSION_PATCH = 0
comptime RAYLIB_VERSION = "6.2"
comptime PI = Float32(3.14159265358979323846)
comptime DEG2RAD = PI / 180
comptime RAD2DEG = 180 / PI

struct FLAG:
    comptime VSYNC_HINT = 64
    comptime FULLSCREEN_MODE = 2
    comptime WINDOW_RESIZABLE = 4
    comptime WINDOW_UNDECORATED = 8
    comptime WINDOW_HIDDEN = 128
    comptime WINDOW_MINIMIZED = 512
    comptime WINDOW_MAXIMIZED = 1024
    comptime WINDOW_UNFOCUSED = 2048
    comptime WINDOW_TOPMOST = 4096
    comptime WINDOW_ALWAYS_RUN = 256
    comptime WINDOW_TRANSPARENT = 16
    comptime WINDOW_HIGHDPI = 8192
    comptime WINDOW_MOUSE_PASSTHROUGH = 16384
    comptime BORDERLESS_WINDOWED_MODE = 32768
    comptime MSAA_4X_HINT = 32
    comptime INTERLACED_HINT = 65536

struct LOG:
    comptime ALL = 0
    comptime TRACE = 1
    comptime DEBUG = 2
    comptime INFO = 3
    comptime WARNING = 4
    comptime ERROR = 5
    comptime FATAL = 6
    comptime NONE = 7

struct KEY:
    comptime NULL = 0
    comptime APOSTROPHE = 39
    comptime COMMA = 44
    comptime MINUS = 45
    comptime PERIOD = 46
    comptime SLASH = 47
    comptime ZERO = 48
    comptime ONE = 49
    comptime TWO = 50
    comptime THREE = 51
    comptime FOUR = 52
    comptime FIVE = 53
    comptime SIX = 54
    comptime SEVEN = 55
    comptime EIGHT = 56
    comptime NINE = 57
    comptime SEMICOLON = 59
    comptime EQUAL = 61
    comptime A = 65
    comptime B = 66
    comptime C = 67
    comptime D = 68
    comptime E = 69
    comptime F = 70
    comptime G = 71
    comptime H = 72
    comptime I = 73
    comptime J = 74
    comptime K = 75
    comptime L = 76
    comptime M = 77
    comptime N = 78
    comptime O = 79
    comptime P = 80
    comptime Q = 81
    comptime R = 82
    comptime S = 83
    comptime T = 84
    comptime U = 85
    comptime V = 86
    comptime W = 87
    comptime X = 88
    comptime Y = 89
    comptime Z = 90
    comptime LEFT_BRACKET = 91
    comptime BACKSLASH = 92
    comptime RIGHT_BRACKET = 93
    comptime GRAVE = 96
    comptime SPACE = 32
    comptime ESCAPE = 256
    comptime ENTER = 257
    comptime TAB = 258
    comptime BACKSPACE = 259
    comptime INSERT = 260
    comptime DELETE = 261
    comptime RIGHT = 262
    comptime LEFT = 263
    comptime DOWN = 264
    comptime UP = 265
    comptime PAGE_UP = 266
    comptime PAGE_DOWN = 267
    comptime HOME = 268
    comptime END = 269
    comptime CAPS_LOCK = 280
    comptime SCROLL_LOCK = 281
    comptime NUM_LOCK = 282
    comptime PRINT_SCREEN = 283
    comptime PAUSE = 284
    comptime F1 = 290
    comptime F2 = 291
    comptime F3 = 292
    comptime F4 = 293
    comptime F5 = 294
    comptime F6 = 295
    comptime F7 = 296
    comptime F8 = 297
    comptime F9 = 298
    comptime F10 = 299
    comptime F11 = 300
    comptime F12 = 301
    comptime LEFT_SHIFT = 340
    comptime LEFT_CONTROL = 341
    comptime LEFT_ALT = 342
    comptime LEFT_SUPER = 343
    comptime RIGHT_SHIFT = 344
    comptime RIGHT_CONTROL = 345
    comptime RIGHT_ALT = 346
    comptime RIGHT_SUPER = 347
    comptime KB_MENU = 348
    comptime KP_0 = 320
    comptime KP_1 = 321
    comptime KP_2 = 322
    comptime KP_3 = 323
    comptime KP_4 = 324
    comptime KP_5 = 325
    comptime KP_6 = 326
    comptime KP_7 = 327
    comptime KP_8 = 328
    comptime KP_9 = 329
    comptime KP_DECIMAL = 330
    comptime KP_DIVIDE = 331
    comptime KP_MULTIPLY = 332
    comptime KP_SUBTRACT = 333
    comptime KP_ADD = 334
    comptime KP_ENTER = 335
    comptime KP_EQUAL = 336
    comptime BACK = 4
    comptime MENU = 5
    comptime VOLUME_UP = 24
    comptime VOLUME_DOWN = 25

struct MOUSE:
    comptime BUTTON_LEFT = 0
    comptime BUTTON_RIGHT = 1
    comptime BUTTON_MIDDLE = 2
    comptime BUTTON_SIDE = 3
    comptime BUTTON_EXTRA = 4
    comptime BUTTON_FORWARD = 5
    comptime BUTTON_BACK = 6
    comptime CURSOR_DEFAULT = 0
    comptime CURSOR_ARROW = 1
    comptime CURSOR_IBEAM = 2
    comptime CURSOR_CROSSHAIR = 3
    comptime CURSOR_POINTING_HAND = 4
    comptime CURSOR_RESIZE_EW = 5
    comptime CURSOR_RESIZE_NS = 6
    comptime CURSOR_RESIZE_NWSE = 7
    comptime CURSOR_RESIZE_NESW = 8
    comptime CURSOR_RESIZE_ALL = 9
    comptime CURSOR_NOT_ALLOWED = 10

struct GAMEPAD:
    comptime BUTTON_UNKNOWN = 0
    comptime BUTTON_LEFT_FACE_UP = 1
    comptime BUTTON_LEFT_FACE_RIGHT = 2
    comptime BUTTON_LEFT_FACE_DOWN = 3
    comptime BUTTON_LEFT_FACE_LEFT = 4
    comptime BUTTON_RIGHT_FACE_UP = 5
    comptime BUTTON_RIGHT_FACE_RIGHT = 6
    comptime BUTTON_RIGHT_FACE_DOWN = 7
    comptime BUTTON_RIGHT_FACE_LEFT = 8
    comptime BUTTON_LEFT_TRIGGER_1 = 9
    comptime BUTTON_LEFT_TRIGGER_2 = 10
    comptime BUTTON_RIGHT_TRIGGER_1 = 11
    comptime BUTTON_RIGHT_TRIGGER_2 = 12
    comptime BUTTON_MIDDLE_LEFT = 13
    comptime BUTTON_MIDDLE = 14
    comptime BUTTON_MIDDLE_RIGHT = 15
    comptime BUTTON_LEFT_THUMB = 16
    comptime BUTTON_RIGHT_THUMB = 17
    comptime AXIS_LEFT_X = 0
    comptime AXIS_LEFT_Y = 1
    comptime AXIS_RIGHT_X = 2
    comptime AXIS_RIGHT_Y = 3
    comptime AXIS_LEFT_TRIGGER = 4
    comptime AXIS_RIGHT_TRIGGER = 5

struct MATERIAL:
    comptime MAP_ALBEDO = 0
    comptime MAP_METALNESS = 1
    comptime MAP_NORMAL = 2
    comptime MAP_ROUGHNESS = 3
    comptime MAP_OCCLUSION = 4
    comptime MAP_EMISSION = 5
    comptime MAP_HEIGHT = 6
    comptime MAP_CUBEMAP = 7
    comptime MAP_IRRADIANCE = 8
    comptime MAP_PREFILTER = 9
    comptime MAP_BRDF = 10

struct SHADER:
    comptime LOC_VERTEX_POSITION = 0
    comptime LOC_VERTEX_TEXCOORD01 = 1
    comptime LOC_VERTEX_TEXCOORD02 = 2
    comptime LOC_VERTEX_NORMAL = 3
    comptime LOC_VERTEX_TANGENT = 4
    comptime LOC_VERTEX_COLOR = 5
    comptime LOC_MATRIX_MVP = 6
    comptime LOC_MATRIX_VIEW = 7
    comptime LOC_MATRIX_PROJECTION = 8
    comptime LOC_MATRIX_MODEL = 9
    comptime LOC_MATRIX_NORMAL = 10
    comptime LOC_VECTOR_VIEW = 11
    comptime LOC_COLOR_DIFFUSE = 12
    comptime LOC_COLOR_SPECULAR = 13
    comptime LOC_COLOR_AMBIENT = 14
    comptime LOC_MAP_ALBEDO = 15
    comptime LOC_MAP_METALNESS = 16
    comptime LOC_MAP_NORMAL = 17
    comptime LOC_MAP_ROUGHNESS = 18
    comptime LOC_MAP_OCCLUSION = 19
    comptime LOC_MAP_EMISSION = 20
    comptime LOC_MAP_HEIGHT = 21
    comptime LOC_MAP_CUBEMAP = 22
    comptime LOC_MAP_IRRADIANCE = 23
    comptime LOC_MAP_PREFILTER = 24
    comptime LOC_MAP_BRDF = 25
    comptime LOC_VERTEX_BONEIDS = 26
    comptime LOC_VERTEX_BONEWEIGHTS = 27
    comptime LOC_MATRIX_BONETRANSFORMS = 28
    comptime LOC_VERTEX_INSTANCETRANSFORM = 29
    comptime UNIFORM_FLOAT = 0
    comptime UNIFORM_VEC2 = 1
    comptime UNIFORM_VEC3 = 2
    comptime UNIFORM_VEC4 = 3
    comptime UNIFORM_INT = 4
    comptime UNIFORM_IVEC2 = 5
    comptime UNIFORM_IVEC3 = 6
    comptime UNIFORM_IVEC4 = 7
    comptime UNIFORM_UINT = 8
    comptime UNIFORM_UIVEC2 = 9
    comptime UNIFORM_UIVEC3 = 10
    comptime UNIFORM_UIVEC4 = 11
    comptime UNIFORM_SAMPLER2D = 12
    comptime ATTRIB_FLOAT = 0
    comptime ATTRIB_VEC2 = 1
    comptime ATTRIB_VEC3 = 2
    comptime ATTRIB_VEC4 = 3

struct PIXELFORMAT:
    comptime UNCOMPRESSED_GRAYSCALE = 1
    comptime UNCOMPRESSED_GRAY_ALPHA = 2
    comptime UNCOMPRESSED_R5G6B5 = 3
    comptime UNCOMPRESSED_R8G8B8 = 4
    comptime UNCOMPRESSED_R5G5B5A1 = 5
    comptime UNCOMPRESSED_R4G4B4A4 = 6
    comptime UNCOMPRESSED_R8G8B8A8 = 7
    comptime UNCOMPRESSED_R32 = 8
    comptime UNCOMPRESSED_R32G32B32 = 9
    comptime UNCOMPRESSED_R32G32B32A32 = 10
    comptime UNCOMPRESSED_R16 = 11
    comptime UNCOMPRESSED_R16G16B16 = 12
    comptime UNCOMPRESSED_R16G16B16A16 = 13
    comptime COMPRESSED_DXT1_RGB = 14
    comptime COMPRESSED_DXT1_RGBA = 15
    comptime COMPRESSED_DXT3_RGBA = 16
    comptime COMPRESSED_DXT5_RGBA = 17
    comptime COMPRESSED_ETC1_RGB = 18
    comptime COMPRESSED_ETC2_RGB = 19
    comptime COMPRESSED_ETC2_EAC_RGBA = 20
    comptime COMPRESSED_PVRT_RGB = 21
    comptime COMPRESSED_PVRT_RGBA = 22
    comptime COMPRESSED_ASTC_4x4_RGBA = 23
    comptime COMPRESSED_ASTC_8x8_RGBA = 24

struct TEXTURE:
    comptime FILTER_POINT = 0
    comptime FILTER_BILINEAR = 1
    comptime FILTER_TRILINEAR = 2
    comptime FILTER_ANISOTROPIC_4X = 3
    comptime FILTER_ANISOTROPIC_8X = 4
    comptime FILTER_ANISOTROPIC_16X = 5
    comptime WRAP_REPEAT = 0
    comptime WRAP_CLAMP = 1
    comptime WRAP_MIRROR_REPEAT = 2
    comptime WRAP_MIRROR_CLAMP = 3

struct CUBEMAP:
    comptime LAYOUT_AUTO_DETECT = 0
    comptime LAYOUT_LINE_VERTICAL = 1
    comptime LAYOUT_LINE_HORIZONTAL = 2
    comptime LAYOUT_CROSS_THREE_BY_FOUR = 3
    comptime LAYOUT_CROSS_FOUR_BY_THREE = 4

struct FONT:
    comptime DEFAULT = 0
    comptime BITMAP = 1
    comptime SDF = 2

struct BLEND:
    comptime ALPHA = 0
    comptime ADDITIVE = 1
    comptime MULTIPLIED = 2
    comptime ADD_COLORS = 3
    comptime SUBTRACT_COLORS = 4
    comptime ALPHA_PREMULTIPLY = 5
    comptime CUSTOM = 6
    comptime CUSTOM_SEPARATE = 7

struct GESTURE:
    comptime NONE = 0
    comptime TAP = 1
    comptime DOUBLETAP = 2
    comptime HOLD = 4
    comptime DRAG = 8
    comptime SWIPE_RIGHT = 16
    comptime SWIPE_LEFT = 32
    comptime SWIPE_UP = 64
    comptime SWIPE_DOWN = 128
    comptime PINCH_IN = 256
    comptime PINCH_OUT = 512

struct CAMERA:
    comptime CUSTOM = 0
    comptime FREE = 1
    comptime ORBITAL = 2
    comptime FIRST_PERSON = 3
    comptime THIRD_PERSON = 4
    comptime PERSPECTIVE = 0
    comptime ORTHOGRAPHIC = 1

struct NPATCH:
    comptime NINE_PATCH = 0
    comptime THREE_PATCH_VERTICAL = 1
    comptime THREE_PATCH_HORIZONTAL = 2

comptime MOUSE_LEFT_BUTTON = 0
comptime MOUSE_RIGHT_BUTTON = 1
comptime MOUSE_MIDDLE_BUTTON = 2

struct MATERIAL_MAP:
    comptime DIFFUSE = 0
    comptime SPECULAR = 1

struct SHADER_LOC_MAP:
    comptime DIFFUSE = 15
    comptime SPECULAR = 16

comptime LIGHTGRAY = Color(200, 200, 200, 255)
comptime GRAY = Color(130, 130, 130, 255)
comptime DARKGRAY = Color(80, 80, 80, 255)
comptime YELLOW = Color(253, 249, 0, 255)
comptime GOLD = Color(255, 203, 0, 255)
comptime ORANGE = Color(255, 161, 0, 255)
comptime PINK = Color(255, 109, 194, 255)
comptime RED = Color(230, 41, 55, 255)
comptime MAROON = Color(190, 33, 55, 255)
comptime GREEN = Color(0, 228, 48, 255)
comptime LIME = Color(0, 158, 47, 255)
comptime DARKGREEN = Color(0, 117, 44, 255)
comptime SKYBLUE = Color(102, 191, 255, 255)
comptime BLUE = Color(0, 121, 241, 255)
comptime DARKBLUE = Color(0, 82, 172, 255)
comptime PURPLE = Color(200, 122, 255, 255)
comptime VIOLET = Color(135, 60, 190, 255)
comptime DARKPURPLE = Color(112, 31, 126, 255)
comptime BEIGE = Color(211, 176, 131, 255)
comptime BROWN = Color(127, 106, 79, 255)
comptime DARKBROWN = Color(76, 63, 47, 255)
comptime WHITE = Color(255, 255, 255, 255)
comptime BLACK = Color(0, 0, 0, 255)
comptime BLANK = Color(0, 0, 0, 0)
comptime MAGENTA = Color(255, 0, 255, 255)
comptime RAYWHITE = Color(245, 245, 245, 255)
