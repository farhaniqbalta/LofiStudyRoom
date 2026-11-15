#!/usr/bin/env python3
"""Composites the packs the way the app layers them, for a quick look without a device.
Usage: python3 Tools/preview.py <Character> <Pet> <Scenery> <out.png> [HH:mm] [--scene <Folder>]
  [--room <key>] [--rain <frame>] [--scenery-anim <name>] [--character-frame <n>] [--pet-frame <n>]"""
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
    opts = {}
    for flag in ("--room", "--rain", "--scenery-anim", "--character-frame", "--pet-frame"):
        if flag in args:
            i = args.index(flag)
            opts[flag] = args[i + 1]
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
                    q = canvas[top + j][x + i]
                    canvas[top + j][x + i] = p if p[3] == 255 else tuple((a * p[3] + b * (255 - p[3])) // 255 for a, b in zip(p, q))
    def draw_frame(category, name, index):
        d, m = load(category, name)
        a = scene["anchors"][m["anchor"]]
        fw = m["frame"]["w"]
        blit(pngio.crop(pngio.read(os.path.join(d, m["sheet"])), index * fw, 0, fw, m["frame"]["h"]), a["x"], a["y"])
    _, sm = load("Scenery", scenery)
    anim = opts.get("--scenery-anim", sm["fallbackAnimation"])
    draw_frame("Scenery", scenery, sm["animations"][anim]["frames"][0])
    if "--rain" in opts:
        r = scene["rain"]
        a = scene["anchors"][r["anchor"]]
        fw = r["frame"]["w"]
        blit(pngio.crop(pngio.read(os.path.join(sdir, r["sheet"])), int(opts["--rain"]) * fw, 0, fw, r["frame"]["h"]), a["x"], a["y"])
    room_file = scene["rooms"][opts["--room"]] if "--room" in opts else scene["room"]
    blit(pngio.read(os.path.join(sdir, room_file)), 0, 0)
    draw_frame("Characters", character, int(opts.get("--character-frame", 0)))
    for fg in scene["foreground"]:
        a = scene["anchors"][fg["anchor"]]
        blit(pngio.read(os.path.join(sdir, fg["image"])), a["x"], a["y"])
    draw_frame("Pets", pet, int(opts.get("--pet-frame", 0)))
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
