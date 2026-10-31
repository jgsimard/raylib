"""Standalone raylib example: only the raylib package and Mojo stdlib are needed."""

from std.sys.arg import argv
from raylib import Color, Window


def main() raises:
    var args = argv()
    if len(args) != 2:
        raise Error("usage: raylib_window <native raylib library path>")
    var window = Window(args[1], 640, 360, String("Mojo raylib"), 60)
    try:
        for _ in range(120):
            if window.should_close():
                break
            var frame = window^.begin_drawing()
            try:
                frame.clear_background(Color(24, 27, 33, 255))
                frame.draw_rectangle(
                    220, 130, 200, 100, Color(90, 180, 240, 255)
                )
            except error:
                window = frame^.end()
                raise error
            window = frame^.end()
    except error:
        window^.close()
        raise error
    window^.close()
