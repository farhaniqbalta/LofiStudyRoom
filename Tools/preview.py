#!/usr/bin/env python3
"""Composites the packs the way the app layers them, for a quick look without a device.
Usage: python3 Tools/preview.py <Character> <Pet> <Scenery> <out.png> [HH:mm] [--scene <Folder>]
  [--room <key>] [--rain <frame>] [--scenery-anim <name>] [--character-frame <n>] [--pet-frame <n>]
  [--music <playing|paused|off>]  music skin: panel, icons, flat placeholders for cover and texts, notes while playing"""
import json, os, sys
import pngio

A = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "LoFiRoom", "Assets")

def load(*parts):
    d = os.path.join(A, *parts)
    return d, json.load(open(os.path.join(d, "manifest.json")))

def main():
    args = sys.argv[1:]
    first = lambda *parts: sorted(os.listdir(os.path.join(A, *parts)))[0]
    registry = json.load(open(os.path.join(A, "art-sets.json")))
    scene_name = registry["sets"][registry["active"]]["scene"]
    if "--scene" in args:
        i = args.index("--scene")
        scene_name = args[i + 1]
        del args[i:i + 2]
    opts = {}
    for flag in ("--music", "--room", "--rain", "--scenery-anim", "--character-frame", "--pet-frame"):
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
    skin = scene.get("music")
    if skin and opts.get("--music", "off") != "off":
        state = opts["--music"]
        blit(pngio.read(os.path.join(sdir, skin["panel"])), skin["frame"]["x"], skin["frame"]["y"])
        isheet = pngio.read(os.path.join(sdir, skin["icons"]["sheet"]))
        iw, ih = skin["icons"]["frame"]["w"], skin["icons"]["frame"]["h"]
        def centre(slot, name):
            sl = skin["slots"][slot]
            i = skin["icons"]["names"].index(name)
            blit(pngio.crop(isheet, i * iw, 0, iw, ih), sl["x"] + (sl["w"] - iw) // 2, sl["y"] + (sl["h"] - ih) // 2)
        def flat(slot, colour, shrink=0):
            sl = skin["slots"][slot]
            blit([[colour] * (sl["w"] - shrink) for _ in range(sl["h"] - 2 * (sl["h"] // 4))], sl["x"], sl["y"] + sl["h"] // 4)
        flat("artwork", (90, 120, 150, 255)); blit([[(90, 120, 150, 255)] * 44 for _ in range(44)], skin["slots"]["artwork"]["x"], skin["slots"]["artwork"]["y"])
        flat("title", (243, 233, 210, 255), 40); flat("artist", (139, 127, 168, 255), 60)
        flat("attribution", (139, 127, 168, 255), 4)
        centre("previous", "previous"); centre("toggle", "pause" if state == "playing" else "play")
        centre("next", "next"); centre("close", "close")
        if state == "playing" and skin.get("notes"):
            n = skin["notes"]
            a = scene["anchors"][n["anchor"]]
            blit(pngio.crop(pngio.read(os.path.join(sdir, n["sheet"])), 0, 0, n["frame"]["w"], n["frame"]["h"]), a["x"], a["y"])
    pngio.write(out, [[p for p in row for _ in range(3)] for row in canvas for _ in range(3)])

main()
