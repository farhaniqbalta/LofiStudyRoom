#!/usr/bin/env python3
"""Composites the packs the way the app layers them, for a quick look without a device.
Usage: python3 Tools/preview.py <Character> <Pet> <Scenery> <out.png> [HH:mm] [--scene <Folder>]"""
import json, os, sys
import pngio

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "LoFiRoom", "Assets")

def load(*parts):
    d = os.path.join(A, *parts)
    return d, json.load(open(os.path.join(d, "manifest.json")))

def main():
    args = sys.argv[1:]
    first = lambda *parts: sorted(os.listdir(os.path.join(A, *parts)))[0]
    scene_name = first("Scenes")
    if "--scene" in args:
        i = args.index("--scene")
        scene_name = args[i + 1]
        del args[i:i + 2]
    character, pet, scenery, out = args[:4]
    text = args[4] if len(args) > 4 else "22:47"
    sdir, scene = load("Scenes", scene_name)
    W, H = scene["canvas"]["w"], scene["canvas"]["h"]
    canvas = [[(0, 0, 0, 255)] * W for _ in range(H)]
    def blit(img, x, y):  # x,y = bottom-left in SpriteKit coordinates
        top = H - y - len(img)
        for j, row in enumerate(img):
            for i, p in enumerate(row):
                if p[3] and 0 <= top + j < H and 0 <= x + i < W:
                    canvas[top + j][x + i] = p
    def frame0(category, name):
        d, m = load(category, name)
        a = scene["anchors"][m["anchor"]]
        blit(pngio.crop(pngio.read(os.path.join(d, m["sheet"])), 0, 0, m["frame"]["w"], m["frame"]["h"]), a["x"], a["y"])
    frame0("Scenery", scenery)
    blit(pngio.read(os.path.join(sdir, scene["room"])), 0, 0)
    frame0("Characters", character)
    for fg in scene["foreground"]:
        a = scene["anchors"][fg["anchor"]]
        blit(pngio.read(os.path.join(sdir, fg["image"])), a["x"], a["y"])
    frame0("Pets", pet)
    skin = next(c for c in sorted(os.listdir(os.path.join(A, "Clocks")))
                if load("Clocks", c)[1]["perspective"] == scene["perspective"])
    cdir, clock = load("Clocks", skin)
    a = scene["anchors"][clock["anchor"]]
    blit(pngio.read(os.path.join(cdir, clock["bezel"])), a["x"], a["y"])
    glyphs = pngio.read(os.path.join(cdir, clock["sheet"]))
    for ch, slot in zip(text, clock["slots"]):
        i = clock["glyphs"].index(ch)
        blit(pngio.crop(glyphs, i * clock["frame"]["w"], 0, clock["frame"]["w"], clock["frame"]["h"]), a["x"] + slot["x"], a["y"] + slot["y"])
    pngio.write(out, [[p for p in row for _ in range(3)] for row in canvas for _ in range(3)])

main()
