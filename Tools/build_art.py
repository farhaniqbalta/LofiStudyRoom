#!/usr/bin/env python3
"""Builds the shipped sprite packs in LoFiRoom/Assets from the raw PixelLab images in ArtSource/ (stdlib only).
Run: python3 Tools/build_art.py
All positions here are top-left based image pixels on the 480x352 room; manifests are written in SpriteKit
coordinates (origin bottom-left). Every pack sprite is placed with its bottom-left corner on its anchor."""
import json, os, shutil
import pngio
from cutout import figure, polygon

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
SRC = os.path.join(ROOT, "ArtSource")
OUT = os.path.join(ROOT, "LoFiRoom", "Assets")
W, H = 480, 352
PERSPECTIVE = "study-room-back-3q-v1"
SAFE = dict(x=14, y=12, w=452, h=328)        # visible on every targeted iPad (5x on 11-inch, 6x on 13-inch)
CLEAR = (0, 0, 0, 0)

WINDOW = (64, 76, 184, 128)                   # x, top, w, h: the scenery sprite; glass is keyed out inside it
SEAT_CROP = (320, 160, 128, 184)              # region sent to PixelLab for the character edits
CLOCK = (294, 211)                            # top-left of the clock skin, covering the painted clock
CAT_FEET = (86, 210)                          # left edge and sill line the cat lies on
POINTS = {"lamp": (282, 225), "computer": (347, 192)}  # tap targets for M2

def rect(x, top, w, h):
    return dict(x=x, y=H - top - h, w=w, h=h)

def pack_dir(*parts):
    path = os.path.join(OUT, *parts)
    os.makedirs(path, exist_ok=True)
    return path

def write_manifest(path, **fields):
    with open(os.path.join(path, "manifest.json"), "w") as f:
        json.dump(fields, f, indent=2)

def sheet(frames):
    return [sum((frame[y] for frame in frames), []) for y in range(len(frames[0]))]

def bbox(images):
    pts = [(x, y) for img in images for y, row in enumerate(img) for x, p in enumerate(row) if p[3]]
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1

def sprite_pack(category, name, kind, anchor, frames, animations, provenance):
    path = pack_dir(category, name)
    pngio.write(os.path.join(path, "sheet.png"), sheet(frames))
    write_manifest(path, id=name.lower(), type=kind, packVersion=1, perspective=PERSPECTIVE, anchor=anchor,
                   sheet="sheet.png", frame=dict(w=len(frames[0][0]), h=len(frames[0])),
                   animations=animations, fallbackAnimation=next(iter(animations)), provenance=provenance)

# ---------- room: key the magenta glass out so scenery behind shows through (this is the window mask)
room = pngio.read(os.path.join(SRC, "room_raw.png"))
wx, wy, ww, wh = WINDOW
for y in range(wy, wy + wh):
    for x in range(wx, wx + ww):
        r, g, b, _ = room[y][x]
        if r > 180 and b > 150 and g < 110:
            room[y][x] = CLEAR

# ---------- characters and the chair that sits in front of them
# The PixelLab edits painted each character into the room's own chair. To get real layers:
#   chair_front = the chair's back board and slats, traced by hand, copied from the room (drawn above the actor)
#   character   = the pixels the edit changed, with the body continued behind chair_front so the sprite has no chair in it
sx, sy, sw, sh = SEAT_CROP
CHAIR_FRONT = [  # room pixels, top-left based
    [(378, 229), (420, 229), (421, 232), (421, 262), (410, 264), (379, 264), (374, 261), (372, 252), (372, 240), (374, 233)],  # back board
    [(386, 264), (394, 264), (391, 290), (382, 290)],  # left slat
    [(406, 264), (416, 264), (413, 289), (403, 289)],  # right slat
]
chair = {(x - sx, y - sy) for pts in CHAIR_FRONT for x, y in polygon(pts)}
before = pngio.crop(pngio.read(os.path.join(SRC, "room_raw.png")), sx, sy, sw, sh)

def bob(img, neck):
    """Rows above the neck drop one pixel; reads as a small nod over the keyboard."""
    return [[CLEAR] * len(img[0])] + img[:neck] + img[neck + 1:]

# Loose outline both seated characters fit inside (crop pixels). It also bounds what a character pack may paint.
ENVELOPE = polygon([(50, 18), (60, 10), (80, 9), (93, 14), (97, 28), (97, 44), (101, 56), (101, 72), (93, 77), (91, 123),
                    (52, 125), (50, 146), (64, 150), (64, 166), (14, 166), (14, 148), (23, 144), (21, 100), (29, 96),
                    (26, 84), (29, 77), (17, 75), (17, 62), (40, 59), (50, 52)])
front = [[before[y][x] if (x, y) in chair else CLEAR for x in range(sw)] for y in range(sh)]

characters = {}
for name, neck, job in (("Boy01", 52, "01c93df1-0248-4bb4-8ed1-0d1bba639e6c"),
                        ("Girl01", 56, "7ba1e19c-e5fc-45b6-a5b4-4d05c9dbe17a")):
    after = pngio.read(os.path.join(SRC, f"{name[:-2].lower()}_edit_raw.png"))
    shape = figure(before, after, ENVELOPE)
    body = [[after[y][x] if (x, y) in shape else CLEAR for x in range(sw)] for y in range(sh)]
    # Continue the body behind the chair: each hidden pixel takes the colour of the nearest body pixel in its row or column.
    for x, y in chair:
        near = [(abs(d), body[y + dy * d][x + dx * d]) for dx, dy in ((1, 0), (0, 1)) for d in range(-40, 41)
                if (x + dx * d, y + dy * d) in shape - chair]
        if near:
            body[y][x] = min(near, key=lambda n: n[0])[1]
    characters[name] = ([body, bob(body, neck)], job)

fx, fy, fw, fh = bbox([f for frames, _ in characters.values() for f in frames] + [front])
seat = rect(sx + fx, sy + fy, fw, fh)
for name, (frames, job) in characters.items():
    sprite_pack("Characters", name, "character", "desk-seat", [pngio.crop(f, fx, fy, fw, fh) for f in frames],
                {"study": dict(frames=[0, 1], fps=1)},
                f"PixelLab edit_image_pixen job {job} on a crop of the room; cut out, body continued behind the chair "
                "and bob frame added by Tools/build_art.py")

# ---------- pets: trim, add a breathing frame, recolour for the black cat
cat = pngio.read(os.path.join(SRC, "cat_orange_raw.png"))
cx, cy, cw, ch = bbox([cat])
cat = pngio.crop(cat, cx, cy - 1, cw, ch + 1)          # one spare row on top for the inhale
mid = len(cat) // 2
inhale = cat[1:mid + 1] + [cat[mid]] + cat[mid + 1:]   # body one pixel taller
def black(p):
    lum = (p[0] * 3 + p[1] * 6 + p[2]) // 10
    return (10 + lum * 22 // 100, 10 + lum * 22 // 100, 16 + lum * 27 // 100, p[3]) if p[3] else p
for name, recolour in (("OrangeCat", lambda p: p), ("BlackCat", black)):
    sprite_pack("Pets", name, "pet", "pet-spot", [[[recolour(p) for p in row] for row in f] for f in (cat, inhale)],
                {"sleep": dict(frames=[0, 1], fps=0.5)},
                "PixelLab create_image_pixen job 23ddd82d-29af-4643-8629-8d9adee3e747; breathing frame"
                + ("" if name == "OrangeCat" else " and recolour") + " by Tools/build_art.py")
pet = rect(CAT_FEET[0], CAT_FEET[1] - len(cat), cw, len(cat))

# ---------- scenery: full-bleed window views; mirror over any border the generator painted
def unframe(img, left, top, right, bottom):
    h, w = len(img), len(img[0])
    def src(i, lo, hi):
        return 2 * lo - i - 1 if i < lo else 2 * hi - i - 1 if i >= hi else i
    return [[img[src(y, top, h - bottom)][src(x, left, w - right)] for x in range(w)] for y in range(h)]
for name, raw, trim, job in (("NeonCity01", "city01_raw.png", (7, 8, 7, 9), "03028076-2912-47c5-b38f-fba53c709160"),
                             ("NeonCity02", "city02_raw.png", (0, 0, 0, 0), "95e608fd-d030-46a5-8b2d-840612fb66f5")):
    img = unframe(pngio.read(os.path.join(SRC, raw)), *trim)
    assert (len(img[0]), len(img)) == (ww, wh), f"{raw} must be {ww}x{wh}"
    sprite_pack("Scenery", name, "scenery", "window-rect", [img], {"idle": dict(frames=[0], fps=1)},
                f"PixelLab create_image_pixen job {job}; border mirrored out by Tools/build_art.py")

# ---------- clock skin: hand-drawn 3x5 emissive digits on a dark screen
GLYPHS = {"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
          "4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001001001001",
          "8": "111101111101111", "9": "111101111001111", ":": "000010000010000"}
LIT = (120, 255, 240, 255)
glyphs = [[[LIT if bits[y * 3 + x] == "1" else CLEAR for x in range(3)] for y in range(5)] for bits in GLYPHS.values()]
BODY, SCREEN = (150, 86, 52, 255), (14, 18, 30, 255)
bezel = [[SCREEN if 1 <= x <= 21 and 2 <= y <= 12 else BODY for x in range(23)] for y in range(15)]
clock_dir = pack_dir("Clocks", "RetroDigital01")
pngio.write(os.path.join(clock_dir, "sheet.png"), sheet(glyphs))
pngio.write(os.path.join(clock_dir, "bezel.png"), bezel)
write_manifest(clock_dir, id="retrodigital01", type="clock", packVersion=1, perspective=PERSPECTIVE, anchor="clock-slot",
               sheet="sheet.png", frame=dict(w=3, h=5), glyphs="".join(GLYPHS), bezel="bezel.png",
               # bottom-left of each of the five glyph slots, relative to the bezel's bottom-left
               slots=[dict(x=x, y=5) for x in (3, 7, 10, 13, 17)],
               provenance="Hand-drawn by Tools/build_art.py")

# ---------- scene
scene_dir = pack_dir("Scenes", "StudyRoom01")
pngio.write(os.path.join(scene_dir, "room.png"), room)
pngio.write(os.path.join(scene_dir, "chair_front.png"), pngio.crop(front, fx, fy, fw, fh))
anchors = {"window-rect": rect(*WINDOW), "window-mask": rect(*WINDOW), "desk-seat": seat, "pet-spot": pet,
           "clock-slot": rect(CLOCK[0], CLOCK[1], 23, 15)}
anchors.update({k: dict(x=x, y=H - top) for k, (x, top) in POINTS.items()})
write_manifest(scene_dir, id="studyroom01", type="scene", packVersion=1, perspective=PERSPECTIVE,
               canvas=dict(w=W, h=H), safe=SAFE, anchors=anchors, room="room.png",
               foreground=[dict(image="chair_front.png", anchor="desk-seat")],
               provenance="PixelLab create_image_pixen job 0c085c34-7866-4ce7-813f-002ac93c9d1b; glass keyed out and "
                          "chair-front occluder traced by Tools/build_art.py")
print("built packs in", os.path.normpath(OUT))
print("anchors", json.dumps(anchors))
