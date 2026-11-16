#!/usr/bin/env python3
"""Builds the shipped sprite packs in LoFiRoom/Assets from the raw PixelLab images in ArtSource/ (stdlib only).
Run: python3 Tools/build_art.py
All positions here are top-left based image pixels on the 480x352 room; manifests are written in SpriteKit
coordinates (origin bottom-left). Every pack sprite is placed with its bottom-left corner on its anchor."""
import collections, json, math, os, random, shutil
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
LAMP_BOX, COMPUTER_BOX = (268, 162, 42, 66), (315, 163, 75, 60)  # tap hotspots: x, top, w, h
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

def tint(img, f):
    """Apply f(r, g, b) -> (r, g, b) to every non-transparent pixel."""
    return [[(*f(*p[:3]), p[3]) if p[3] else p for p in row] for row in img]

def lerp(c, target, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(c, target))

def bbox(images):
    pts = [(x, y) for img in images for y, row in enumerate(img) for x, p in enumerate(row) if p[3]]
    xs, ys = [p[0] for p in pts], [p[1] for p in pts]
    return min(xs), min(ys), max(xs) - min(xs) + 1, max(ys) - min(ys) + 1

def sprite_pack(category, name, kind, anchor, frames, animations, provenance, **extra):
    path = pack_dir(category, name)
    pngio.write(os.path.join(path, "sheet.png"), sheet(frames))
    write_manifest(path, id=name.lower(), type=kind, packVersion=1, perspective=PERSPECTIVE, anchor=anchor,
                   sheet="sheet.png", frame=dict(w=len(frames[0][0]), h=len(frames[0])),
                   animations=animations, fallbackAnimation=next(iter(animations)), provenance=provenance, **extra)

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
# Routine poses reach further (raised mug, elbows out), so they get a wider outline for the upper body.
POSE_ENVELOPE = ENVELOPE | polygon([(8, 4), (122, 4), (122, 82), (101, 82), (93, 77), (40, 59), (17, 62), (17, 75), (8, 75)])
front = [[before[y][x] if (x, y) in chair else CLEAR for x in range(sw)] for y in range(sh)]

def differs(p, q, threshold=8):
    return max(abs(p[i] - q[i]) for i in range(3)) > threshold

def cut(after, shape):
    """The figure as a sprite with no chair in it: hidden pixels behind the chair take the nearest body colour."""
    body = [[after[y][x] if (x, y) in shape else CLEAR for x in range(sw)] for y in range(sh)]
    visible = shape - chair
    for x, y in chair:
        near = [(abs(d), body[y + dy * d][x + dx * d]) for dx, dy in ((1, 0), (0, 1)) for d in range(-40, 41)
                if (x + dx * d, y + dy * d) in visible]
        if near:
            body[y][x] = min(near, key=lambda n: n[0])[1]
    return body

def pose_shape(rest_after, rest_shape, pose_after):
    """A pose is an edit of the rest picture: keep what was body or what the edit changed, then drop pixels
    that went back to showing the room (an arm that left the keyboard)."""
    return {(x, y) for x, y in POSE_ENVELOPE
            if ((x, y) in rest_shape or differs(pose_after[y][x], rest_after[y][x]))
            and differs(pose_after[y][x], before[y][x], 12)}

def one_shot(fps, frames, weight, cooldown):
    return dict(frames=frames, fps=fps, loop=False, safeExits=[], routine=dict(weight=weight, cooldown=cooldown))

POSES = {  # PixelLab edit_image_pixen jobs, each an edit of the character's rest picture
    "Boy01": dict(drink="eb6bf14f-d1cd-4fc3-a1d9-5847c0592368", stretch="9e28eaa2-60bd-438d-b318-c512197fcfb3",
                  rest="d37d0deb-8676-49d8-b917-7b0288e5f67a"),
    "Girl01": dict(drink="d677a003-6fb9-455e-a034-b6af5e07a8c2", stretch="5f911362-7571-4162-872d-7a0cce043704",
                   rest="f1ff52c5-c21b-4be9-9dfe-2a8203d840cf"),
}
characters = {}
for name, neck, job in (("Boy01", 52, "01c93df1-0248-4bb4-8ed1-0d1bba639e6c"),
                        ("Girl01", 56, "7ba1e19c-e5fc-45b6-a5b4-4d05c9dbe17a")):
    who = name[:-2].lower()
    after = pngio.read(os.path.join(SRC, f"{who}_edit_raw.png"))
    shape = figure(before, after, ENVELOPE)
    body = cut(after, shape)
    frames = [body, bob(body, neck)]
    for pose in ("drink", "stretch", "rest"):
        pose_after = pngio.read(os.path.join(SRC, f"{who}_{pose}_raw.png"))
        frames.append(cut(pose_after, pose_shape(after, shape, pose_after)))
    characters[name] = (frames, job)

fx, fy, fw, fh = bbox([f for frames, _ in characters.values() for f in frames] + [front])
seat = rect(sx + fx, sy + fy, fw, fh)
for name, (frames, job) in characters.items():
    sprite_pack("Characters", name, "character", "desk-seat", [pngio.crop(f, fx, fy, fw, fh) for f in frames],
                {"study": dict(frames=[0, 1], fps=1),
                 # one held pose each: 2.5 s, 3 s and 8 s
                 "drink": one_shot(0.4, [2], 3, 300),
                 "stretch": one_shot(1 / 3, [3], 1, 900),
                 "rest": one_shot(0.125, [4], 2, 600)},
                f"PixelLab edit_image_pixen job {job} on a crop of the room (rest), and jobs "
                + ", ".join(f"{POSES[name][k]} ({k})" for k in ("drink", "stretch", "rest"))
                + " as edits of the rest picture; cut out, body continued behind the chair and bob frame added by Tools/build_art.py.")

# ---------- pets: the anchor matches the cat sprite (37x28 with spare rows on top)
cat = pngio.read(os.path.join(SRC, "cat_orange_raw.png"))
cx, cy, cw, ch = bbox([cat])
CAT_PAD = 2  # spare rows on top for the inhale and the startle hop
cat = [[CLEAR] * cw for _ in range(CAT_PAD - 1)] + pngio.crop(cat, cx, cy - 1, cw, ch + 1)
# The cat packs themselves come from ArtLab/type-a-lofi/*.aseprite (exported at the end); this only sizes the pet anchor.
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
    day = tint(img, lambda r, g, b: lerp((r, g, b), (190, 215, 235), 0.55) if r + g + b < 450 else (r, g, b))
    sprite_pack("Scenery", name, "scenery", "window-rect", [img, day],
                {"night": dict(frames=[0], fps=1), "day": dict(frames=[1], fps=1)},
                f"PixelLab create_image_pixen job {job}; border mirrored out by Tools/build_art.py. Stand-in frames: day.",
                phases={"night": "night", "day": "day"})

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

# ---------- room variants: lamp-off is a PixelLab edit of the lamp area; daylight is still a crude stand-in recolour
LAMP_CROP = (136, 150)  # where the 256x160 crop sent to PixelLab sits in the room
GLOW_ABOVE = (226, 112, 404)  # x0, top, x1: wall under the shelf that the lamp also lit, above that crop
def lamp_off(img):
    """Patches the PixelLab lamp-off picture into the room, only where the original was lit, and shifts its colours
    so the patch meets the untouched wall without a seam (the edit re-tinted the whole crop a little)."""
    original = pngio.read(os.path.join(SRC, "room_raw.png"))
    edit = pngio.read(os.path.join(SRC, "lamp_off_raw.png"))
    lx, ly = LAMP_CROP
    lit, shift, count = set(), [0, 0, 0], 0
    for j, row in enumerate(edit):
        for i, p in enumerate(row):
            o = original[ly + j][lx + i]
            if sum(o[:3]) - sum(p[:3]) > 45:   # clearly darker in the edit: this was lamp light
                lit.add((i, j))
            elif not differs(o, p, 60):         # ordinary unlit surface: measure the edit's colour drift
                shift = [shift[c] + o[c] - p[c] for c in range(3)]
                count += 1
    shift = [round(v / max(count, 1)) for v in shift]
    out = [row[:] for row in img]
    remap = {}  # lit colour -> its unlit colour, learned from the patched area
    for i, j in lit:
        if out[ly + j][lx + i][3]:
            unlit = (*[max(0, min(255, edit[j][i][c] + shift[c])) for c in range(3)], 255)
            out[ly + j][lx + i] = unlit
            remap.setdefault(original[ly + j][lx + i], collections.Counter())[unlit] += 1
    # The lamp's glow also reaches the wall above the crop sent to PixelLab. Recolour it with the same
    # lit -> unlit mapping, so the edge of the patch does not show.
    for y in range(GLOW_ABOVE[1], ly):
        for x in range(GLOW_ABOVE[0], GLOW_ABOVE[2]):
            if original[y][x] in remap and out[y][x][3]:
                out[y][x] = remap[original[y][x]].most_common(1)[0][0]
    return out

def daylight(img):  # mild: actors are not tinted, so keep the dark chair pixels plausible
    return tint(img, lambda r, g, b: lerp((r, g, b), (245, 228, 200), 0.45))

# ---------- rain: a looping one-row sheet; each streak falls RAIN_STEP px per frame and the pattern repeats every
# RAIN_PERIOD rows, so frame 6 is frame 0
RAIN_FRAMES, RAIN_STEP, RAIN_PERIOD, RAIN_COLOUR = 6, 8, 48, (170, 210, 255, 160)
def rain_sheet():
    rng = random.Random(7)
    # One drop per 4 px column band, so the whole pane rains evenly (random columns left gaps).
    drops = [(x + rng.randrange(3), rng.randrange(RAIN_PERIOD)) for x in range(2, ww - 2, 4)]
    frames = []
    for f in range(RAIN_FRAMES):
        img = [[CLEAR] * ww for _ in range(wh)]
        for x, y0 in drops:
            for y in range(y0 + f * RAIN_STEP - RAIN_PERIOD, wh, RAIN_PERIOD):
                for k in range(3):  # 1x3 diagonal streak
                    if 0 <= y + k < wh:
                        img[y + k][x - (k + 1) // 2] = RAIN_COLOUR
        frames.append(img)
    return frames

# ---------- music skin: a wall-mounted pixel player (panel, icons, notes) for the Spotify now-playing display
PANEL_AT, PANEL_SIZE = (58, 228), (176, 56)    # top-left on the room, size
BODY_C, EDGE_C, HILITE_C, WELL_C, LED_C, ICON_C = (22, 18, 40, 255), (118, 92, 160, 255), (58, 46, 92, 255), (12, 10, 24, 255), (240, 170, 70, 255), (243, 233, 210, 255)
CYAN_C = (120, 220, 235, 255)
MUSIC_SLOTS = dict(artwork=(6, 6, 44, 44), title=(56, 6, 104, 13), artist=(56, 20, 104, 11), attribution=(128, 38, 42, 12),
                   previous=(58, 36, 16, 16), toggle=(80, 36, 16, 16), next=(102, 36, 16, 16), close=(164, 4, 8, 8),
                   message=(56, 6, 114, 24), action=(56, 34, 114, 16))

def panel_image():
    pw, ph = PANEL_SIZE
    img = [[BODY_C] * pw for _ in range(ph)]
    def px(x, y, c): img[y][x] = c
    for x in range(pw):
        px(x, 0, EDGE_C); px(x, ph - 1, EDGE_C)
    for y in range(ph):
        px(0, y, EDGE_C); px(pw - 1, y, EDGE_C)
    for x, y in ((0, 0), (pw - 1, 0), (0, ph - 1), (pw - 1, ph - 1)):
        px(x, y, CLEAR)
    for x in range(2, pw - 2):
        px(x, 1, HILITE_C)
    for i in range(46):  # recessed cover well
        for x, y in ((5 + i, 5), (5 + i, 50), (5, 5 + i), (50, 5 + i)):
            px(x, y, HILITE_C)
    for y in range(6, 50):
        for x in range(6, 50):
            px(x, y, WELL_C)
    for x in range(56, 170):  # divider under the text area
        px(x, 33, HILITE_C)
    px(166, 16, LED_C); px(169, 16, LED_C)
    return img

def bitmap(rows, colour=ICON_C):
    return [[colour if c == "X" else CLEAR for c in row] for row in rows]

def paste(canvas, rows, x, y):
    for j, row in enumerate(rows):
        for i, c in enumerate(row):
            if c == "X":
                canvas[y + j][x + i] = ICON_C

TRI_R = ["X....", "XX...", "XXX..", "XXXX.", "XXXXX", "XXXX.", "XXX..", "XX...", "X...."]
PLAY = ["X......", "XX.....", "XXX....", "XXXX...", "XXXXX..", "XXXXXX.", "XXXXX..", "XXXX...", "XXX....", "XX.....", "X......"]
BAR = ["XX"] * 9
PAUSE_BAR = ["XXX"] * 11
CLOSE = [["X" if abs(x - y) <= 1 or abs(x - (7 - y)) <= 1 else "." for x in range(8)] for y in range(8)]
def icon(*parts):
    canvas = [[CLEAR] * 16 for _ in range(16)]
    for rows, x, y in parts:
        paste(canvas, rows, x, y)
    return canvas
ICON_NEXT = icon((TRI_R, 3, 3), (TRI_R, 8, 3), (BAR, 13, 3))
ICON_PREVIOUS = [row[::-1] for row in ICON_NEXT]
ICON_PLAY = icon((PLAY, 4, 2))
ICON_PAUSE = icon((PAUSE_BAR, 4, 2), (PAUSE_BAR, 9, 2))
ICON_CLOSE = icon((["".join(r) for r in CLOSE], 4, 4))

def note(canvas, x, y, colour):
    """Eighth note, 5x8 px, top-left at x, y."""
    for j, row in enumerate(("..XXX", "..X.X", "..X..", "..X..", "..X..", ".XX..", "XXX..", ".X...")):
        for i, c in enumerate(row):
            if c == "X" and 0 <= y + j < 24 and 0 <= x + i < 20:
                canvas[y + j][x + i] = colour
def notes_frame(f):
    canvas = [[CLEAR] * 20 for _ in range(24)]
    note(canvas, 3 + (f % 2) * 2, 16 - 4 * f, LED_C)             # amber note rises and sways
    note(canvas, 12 - (f % 2) * 2, 16 - 4 * ((f + 2) % 4), CYAN_C)  # cyan note half a loop behind
    return canvas

music_dir = pack_dir("Scenes", "StudyRoom01")
pngio.write(os.path.join(music_dir, "music_panel.png"), panel_image())
pngio.write(os.path.join(music_dir, "music_icons.png"), sheet([ICON_PREVIOUS, ICON_PLAY, ICON_PAUSE, ICON_NEXT, ICON_CLOSE]))
pngio.write(os.path.join(music_dir, "music_notes.png"), sheet([notes_frame(f) for f in range(4)]))

# ---------- scene
scene_dir = pack_dir("Scenes", "StudyRoom01")
pngio.write(os.path.join(scene_dir, "room.png"), room)
rooms = {"night-on": room, "night-off": lamp_off(room), "day-on": daylight(room), "day-off": daylight(lamp_off(room))}
files = {"night-on": "room.png", "night-off": "room_night_off.png", "day-on": "room_day.png", "day-off": "room_day_off.png"}
for key, img in rooms.items():
    pngio.write(os.path.join(scene_dir, files[key]), img)
pngio.write(os.path.join(scene_dir, "rain.png"), sheet(rain_sheet()))
pngio.write(os.path.join(scene_dir, "chair_front.png"), pngio.crop(front, fx, fy, fw, fh))
anchors = {"window-rect": rect(*WINDOW), "window-mask": rect(*WINDOW), "desk-seat": seat, "pet-spot": pet,
           "clock-slot": rect(CLOCK[0], CLOCK[1], 23, 15)}
anchors.update({k: dict(x=x, y=H - top) for k, (x, top) in POINTS.items()})
def panel_slot(name):
    x, y, w, h = MUSIC_SLOTS[name]
    return rect(PANEL_AT[0] + x, PANEL_AT[1] + y, w, h)
# Notes frame: 2 px above the higher of the two rest-pose heads, centred on them (top-left room pixels).
seat_top = sy + fy
head_top = seat_top + min(next(j for j, row in enumerate(pngio.crop(f[0], fx, fy, fw, fh)) if any(p[3] for p in row)) for f, _ in characters.values())
anchors["music-notes"] = dict(x=sx + fx + 57 - 2, y=H - (head_top - 2))
write_manifest(scene_dir, id="studyroom01", type="scene", artSet="A", packVersion=1, perspective=PERSPECTIVE,
               canvas=dict(w=W, h=H), safe=SAFE, anchors=anchors, room="room.png",
               foreground=[dict(image="chair_front.png", anchor="desk-seat")],
               provenance="PixelLab create_image_pixen job 0c085c34-7866-4ce7-813f-002ac93c9d1b; glass keyed out and "
                          "chair-front occluder traced by Tools/build_art.py. Lamp-off room: PixelLab edit_image_pixen job 1caa32ca-cc50-4c08-95f8-89f9b91583ea on a crop around the lamp, patched in. Stand-in frames: day rooms, rain.",
               rooms=files, standIns=["rooms", "rain", "music"],
               music=dict(panel="music_panel.png", frame=rect(*PANEL_AT, *PANEL_SIZE),
                          icons=dict(sheet="music_icons.png", frame=dict(w=16, h=16), names=["previous", "play", "pause", "next", "close"]),
                          slots={name: panel_slot(name) for name in MUSIC_SLOTS},
                          textColor="#F3E9D2", dimColor="#8B7FA8",
                          notes=dict(sheet="music_notes.png", frame=dict(w=20, h=24), fps=2, anchor="music-notes")),
               rain=dict(sheet="rain.png", frame=dict(w=ww, h=wh), fps=8, anchor="window-rect"),
               hotspots=dict(pet=pet, window=rect(*WINDOW), lamp=rect(*LAMP_BOX), computer=rect(*COMPUTER_BOX)))
print("built packs in", os.path.normpath(OUT))
print("anchors", json.dumps(anchors))

# ---------- Aseprite-made packs of art set A (the cats): exported last, so the scene manifest they are checked against exists
import glob, aseprite_export
for source in sorted(glob.glob(os.path.join(ROOT, "ArtLab", "type-a-lofi", "*.aseprite"))):
    aseprite_export.export(source, OUT)
