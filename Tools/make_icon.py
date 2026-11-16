#!/usr/bin/env python3
"""Builds the app icon from art set A: the boy at his desk under the lamp, cropped from the composited room and
scaled up with nearest-neighbour so the pixels stay crisp (stdlib only).
Run after Tools/build_art.py:  python3 Tools/make_icon.py"""
import os, subprocess, sys, tempfile
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import pngio

ROOT = os.path.join(HERE, "..")
ICONSET = os.path.join(ROOT, "LoFiRoom", "App", "Resources.xcassets", "AppIcon.appiconset")
CROP = (272, 150, 128, 128)   # room pixels, top-left based: lamp, monitor, the boy's head and shoulders
SCALE = 8                     # 128 * 8 = 1024, the single universal icon size

with tempfile.TemporaryDirectory() as tmp:
    composite = os.path.join(tmp, "room.png")
    subprocess.run([sys.executable, os.path.join(HERE, "preview.py"), "Boy01", "OrangeCat", "NeonCity01", composite,
                    "22:47", "--scene", "StudyRoom01"], check=True, stdout=subprocess.DEVNULL)
    room3x = pngio.read(composite)
room = [row[::3] for row in room3x[::3]]          # preview.py renders at 3x
x, y, w, h = CROP
crop = pngio.crop(room, x, y, w, h)
icon = [[(*p[:3], 255) for p in row for _ in range(SCALE)] for row in crop for _ in range(SCALE)]  # icons are opaque
assert (len(icon[0]), len(icon)) == (1024, 1024)
os.makedirs(ICONSET, exist_ok=True)
pngio.write(os.path.join(ICONSET, "AppIcon.png"), icon)
with open(os.path.join(ICONSET, "Contents.json"), "w") as f:
    f.write('{\n  "images" : [ { "filename" : "AppIcon.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" } ],\n'
            '  "info" : { "author" : "xcode", "version" : 1 }\n}\n')
print("wrote", os.path.relpath(os.path.join(ICONSET, "AppIcon.png"), ROOT))
