#!/usr/bin/env python3
"""Art set D: turns the user's hand edit of room 3a into clean layer PNGs (stdlib only).
Run from the repo root: python3 ArtLab/type-d-capsule/cut_layers.py

The edited file (raw/room-3a-nochair.png) came back re-rendered: ~50,000 colours instead of 71, slightly soft.
So the clean room keeps the original PixelLab pixels everywhere except where the chair was, and there uses the
user's fill snapped to the original palette. The chair keeps the original pixels under the user's chair mask.
The user's files in raw/ are never changed."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "Tools"))
import pngio

RAW, OUT = os.path.join(HERE, "raw"), os.path.join(HERE, "layers")
CLEAR = (0, 0, 0, 0)
ZONE = (225, 195, 375, 352)   # x0, top, x1, bottom: where the user painted (chair, its shadow, relit floor)
EDITED = 40                   # colour distance that counts as painted, above the re-render noise (~20)
GROW = 2                      # px added around the painted area so its edge blends

orig = pngio.read(os.path.join(RAW, "room-3a.png"))
edit = pngio.read(os.path.join(RAW, "room-3a-nochair.png"))
chair_in = pngio.read(os.path.join(RAW, "chair.png"))
H, W = len(orig), len(orig[0])
assert len(edit) == len(chair_in) == H and len(edit[0]) == len(chair_in[0]) == W, "all three must be 480x352"

palette = sorted({p[:3] for row in orig for p in row})
cache = {}
def snap(c):
    if c not in cache:
        cache[c] = min(palette, key=lambda q: (q[0]-c[0])**2 + (q[1]-c[1])**2 + (q[2]-c[2])**2)
    return cache[c]

mask = [[chair_in[y][x][3] >= 128 for x in range(W)] for y in range(H)]
# Painted area: the connected patch of real changes that touches the chair. Re-render noise elsewhere is thin
# outlines, so it is never connected to it inside ZONE.
x0, y0, x1, y1 = ZONE
changed = [[x0 <= x < x1 and y0 <= y < y1 and (mask[y][x] or sum(abs(orig[y][x][i] - edit[y][x][i]) for i in range(3)) > EDITED)
            for x in range(W)] for y in range(H)]
seen, stack = set(), [(x, y) for y in range(H) for x in range(W) if mask[y][x]]
while stack:
    x, y = stack.pop()
    if (x, y) in seen or not (0 <= x < W and 0 <= y < H) or not changed[y][x]:
        continue
    seen.add((x, y))
    stack += [(x + dx, y + dy) for dx in (-1, 0, 1) for dy in (-1, 0, 1)]
near = [[any((i, j) in seen for j in range(y - GROW, y + GROW + 1) for i in range(x - GROW, x + GROW + 1)) if x0 - GROW <= x < x1 + GROW and y0 - GROW <= y < y1 + GROW else False
         for x in range(W)] for y in range(H)]

room = [[(*snap(edit[y][x][:3]), 255) if near[y][x] else orig[y][x] for x in range(W)] for y in range(H)]
chair = [[orig[y][x] if mask[y][x] else CLEAR for x in range(W)] for y in range(H)]

# Self-check: outside the chair area the room is the original, and every colour comes from the original palette.
assert all(room[y][x] == orig[y][x] for y in range(H) for x in range(W) if not near[y][x])
assert {p[:3] for row in room for p in row} <= set(palette)
assert {p[3] for row in chair for p in row} <= {0, 255}

# Window glass: the drawn city is removed so the scenery pack shows through (layering rule: room glass is transparent).
# Inside each pane polygon, sky, building and window-light colours go; then leftover specks (building outlines) that are
# not part of a larger object (curtain, plant, cords) go too. The laptop's box is kept whole.
PANES = [[(14, 17), (92, 33), (92, 238), (14, 238)],        # left; starts at the safe area's x 14, where the city starts
         [(104, 38), (186, 60), (186, 238), (104, 238)],    # middle
         [(193, 62), (232, 70), (232, 206), (193, 206)]]    # right, its right edge is the curtain
KEEP_BOX = (163, 196, 207, 238)                             # laptop: x0, top, x1, bottom
SCENERY = {(107, 213, 211), (117, 218, 217), (134, 224, 227), (110, 234, 229), (97, 149, 160), (73, 170, 169), (60, 128, 131),
           (91, 117, 137), (94, 123, 143), (80, 100, 122), (85, 107, 129), (73, 88, 113), (68, 79, 104), (61, 64, 90),
           (48, 53, 75), (51, 47, 75), (233, 193, 136), (254, 249, 213), (251, 215, 121)}
SPECK = 40   # a leftover patch smaller than this (in px) inside a pane is city detail, not an object

def inside(x, y, poly):
    hit = False
    for (ax, ay), (bx, by) in zip(poly, poly[1:] + poly[:1]):
        if (ay > y) != (by > y) and x < ax + (y - ay) * (bx - ax) / (by - ay):
            hit = not hit
    return hit

kx0, ky0, kx1, ky1 = KEEP_BOX
glass = [[any(inside(x + .5, y + .5, p) for p in PANES) and not (kx0 <= x < kx1 and ky0 <= y < ky1) for x in range(W)] for y in range(H)]
for y in range(H):
    for x in range(W):
        if glass[y][x] and room[y][x][:3] in SCENERY:
            room[y][x] = CLEAR
done = set()
for y in range(H):
    for x in range(W):
        if glass[y][x] and room[y][x][3] and (x, y) not in done:
            patch, stack, edge = [], [(x, y)], False
            while stack:
                i, j = stack.pop()
                if (i, j) in done or not room[j][i][3]:
                    continue
                if not glass[j][i]:
                    edge = True   # joins something outside the glass: curtain, frame, desk object
                    continue
                done.add((i, j)); patch.append((i, j))
                stack += [(i + 1, j), (i - 1, j), (i, j + 1), (i, j - 1)]
            if not edge and len(patch) < SPECK:
                for i, j in patch:
                    room[j][i] = CLEAR
assert sum(1 for row in room for p in row if not p[3]) > 20000, "the glass should be mostly transparent"

# Lamp off: PixelLab's edit darkened its whole 128x128 crop (plants and curtain too), so it is used only where the
# room is warm-lit by the lamp (warm and bright: the cone on the wall, the desk top, the lamp itself). Colours are
# snapped to the room's palette; glass stays transparent.
LAMP_CROP = (236, 120)   # top-left of the crop in the room
def lamp_lit(p):
    r, g, b = p[:3]
    return p[3] and r > b + 25 and r + g + b > 240
off_crop = pngio.read(os.path.join(RAW, "lamp-off-crop.png"))
room_off = [list(row) for row in room]
for j, row in enumerate(off_crop):
    for i, p in enumerate(row):
        x, y = LAMP_CROP[0] + i, LAMP_CROP[1] + j
        if lamp_lit(room[y][x]):
            room_off[y][x] = (*snap(p[:3]), 255)
# The desk runs on left of the crop; fade the unlit desk into the lit one with a dither so there is no seam
# (the floor and bed are lit by the paper lantern and stay as they are). Each lit colour gets the unlit colour it
# most often got inside the crop.
votes = {}
for j in range(len(off_crop)):
    for i in range(len(off_crop[0])):
        x, y = LAMP_CROP[0] + i, LAMP_CROP[1] + j
        if lamp_lit(room[y][x]):
            v = votes.setdefault(room[y][x], {})
            v[room_off[y][x]] = v.get(room_off[y][x], 0) + 1
lit_to_off = {k: max(v, key=v.get) for k, v in votes.items()}
FADE = 16   # px of desk left of the crop that fade from unlit to lit
for y in range(LAMP_CROP[1], LAMP_CROP[1] + len(off_crop)):
    for x in range(LAMP_CROP[0] - FADE, LAMP_CROP[0]):
        d = LAMP_CROP[0] - x
        if room[y][x] in lit_to_off and lamp_lit(room[y][x]) and (
                (d <= FADE // 2 and (x + y) % 2 == 0) or (x % 2 == 0 and y % 2 == 0)):
            room_off[y][x] = lit_to_off[room[y][x]]
assert sum(a != b for ra, rb in zip(room, room_off) for a, b in zip(ra, rb)) > 3000, "the lamp area should change"

# The boy and his chair, from the user's image cut out by PixelLab (raw/boy-<pose>-cut.png, 160x200, top-left at
# CUT_AT in the room). The chair is furniture, so it goes into the room picture; its near armrest and post cross the
# boy's hip, so they also become a foreground piece. What is left is the boy, one frame per pose.
CUT_AT = (200, 150)
POSES = ["study", "drink", "rest", "lean"]
def chair_part(x, y):            # crop coordinates
    back = 58 <= y < 127 and x >= 126 - (y - 58) * 12 / 60   # behind his back, front edge slanting 126 -> 114
    seat_base = y >= 127 and x >= 52                         # under his thighs, right of his calves
    return back or seat_base or armrest(x, y)
def armrest(x, y):
    return (66 <= x < 114 and 101 <= y < 111) or (89 <= x < 98 and 111 <= y < 127)
# Drink, rest and lean were regenerated from the sharp study crop; the soft first versions stay in raw/.
CUT_FILES = {"study": "boy-study-cut.png", "drink": "boy-drink-cut-sharp.png", "rest": "boy-rest-cut-sharp.png",
             "lean": "boy-lean-cut-sharp.png"}
cuts = {p: pngio.read(os.path.join(RAW, CUT_FILES[p])) for p in POSES}
# The study pose has a sharper source: the user's full-size image shrunk by majority colour per block
# (raw/boy-study-crop-sharp.png, same 160x200 crop). Use its colours under the cut's shape.
sharp = pngio.read(os.path.join(RAW, "boy-study-crop-sharp.png"))
cuts["study"] = [[(*sharp[y][x][:3], c[3]) for x, c in enumerate(row)] for y, row in enumerate(cuts["study"])]
CW, CH = len(cuts["study"][0]), len(cuts["study"])
ax, ay = CUT_AT
chair_px = {(x, y): (*snap(cuts["study"][y][x][:3]), 255) for y in range(CH) for x in range(CW)
            if cuts["study"][y][x][3] > 127 and chair_part(x, y)}
for r in (room, room_off):
    for (x, y), p in chair_px.items():
        r[ay + y][ax + x] = p
boy = {p: [[(*snap(c[y][x][:3]), 255) if c[y][x][3] > 127 and not chair_part(x, y) else CLEAR for x in range(CW)] for y in range(CH)]
       for p, c in cuts.items()}
opaque = [(x, y) for b in boy.values() for y in range(CH) for x in range(CW) if b[y][x][3]]
bx0, by0 = min(x for x, _ in opaque), min(y for _, y in opaque)
bx1, by1 = max(x for x, _ in opaque) + 1, max(y for _, y in opaque) + 1
SEAT = (ax + bx0, ay + by0, bx1 - bx0, by1 - by0)          # x, top, w, h in the room: the character frame
front = [[chair_px.get((x, y), CLEAR) if armrest(x, y) else CLEAR for x in range(bx0, bx1)] for y in range(by0, by1)]
assert sum(p[3] > 0 for row in front for p in row) > 100, "the armrest should be in the foreground piece"
assert all(sum(p[3] > 0 for row in b for p in row) > 3000 for b in boy.values()), "each pose should keep the boy"

# The city frame starts at the safe area (x 14): the glass left of it keeps the original room pixels.
CITY = (14, 14, 220, 224)        # x, top, w, h in the room
city_src = pngio.read(os.path.join(RAW, "city-night.png"))   # 232x224, drawn for the window from x 2
city = [row[CITY[0] - 2:CITY[0] - 2 + CITY[2]] for row in city_src]
city_day = [row[CITY[0] - 2:CITY[0] - 2 + CITY[2]] for row in pngio.read(os.path.join(RAW, "city-day.png"))]

# Day rooms: a mild warm tint, as set A does. The actors and the armrest (a foreground piece shared by day and night)
# are not tinted, so the chair is left untinted too and they stay matched. Glass stays clear.
chair_room = {(ax + x, ay + y) for x, y in chair_px}
def daylight(img):
    return [[(*(round(c + (t - c) * 0.22) for c, t in zip(p[:3], (255, 226, 180))), 255) if p[3] and (x, y) not in chair_room else p
             for x, p in enumerate(row)] for y, row in enumerate(img)]

# The cat: a 48x48 PixelLab sleeping cat (raw/cat2-sleep.png) that came with a teal cushion rim behind its back.
# The cushion is furniture, so its pixels go into the room under the cat (both layers draw together, so a pixel
# put on the wrong side looks the same). The sprite keeps the cat, plus a breathing frame (upper body one row up)
# and a startle-hop frame (whole cat one row up) for the tap reaction until an awake frame is drawn.
CAT_AT = (100, 247)              # top-left of the 48x48 source in the room; must match export.py's pet-spot
def is_teal(p):
    r, g, b = p[:3]
    return p[3] > 127 and g > r + 15 and b > r
cat_src = pngio.read(os.path.join(RAW, "cat2-sleep.png"))
n = len(cat_src)
def beside(x, y, test):
    return any(0 <= x + dx < n and 0 <= y + dy < n and test(cat_src[y + dy][x + dx]) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
fur = lambda p: p[3] > 127 and not is_teal(p) and sum(p[:3]) > 120
cushion = {(x, y) for y in range(n) for x in range(n) if y <= 22 and cat_src[y][x][3] > 127 and (
    is_teal(cat_src[y][x]) or y <= 6 or (sum(cat_src[y][x][:3]) <= 120 and beside(x, y, is_teal) and not beside(x, y, fur)))}
for (x, y) in cushion:
    for r in (room, room_off):
        r[CAT_AT[1] + y][CAT_AT[0] + x] = (*snap(cat_src[y][x][:3]), 255)
cat = [[(*p[:3], 255) if p[3] > 127 and (x, y) not in cushion else CLEAR for x, p in enumerate(row)] for y, row in enumerate(cat_src)]
pts = [(x, y) for y, row in enumerate(cat) for x, p in enumerate(row) if p[3]]
cx0, cy0, cx1, cy1 = min(x for x, _ in pts), min(y for _, y in pts) - 1, max(x for x, _ in pts) + 1, max(y for _, y in pts) + 1
sleep = [row[cx0:cx1] for row in cat[cy0:cy1]]
mid = len(sleep) // 2
breath = sleep[1:mid] + [sleep[mid - 1]] + sleep[mid:]
hop = sleep[1:] + [[CLEAR] * len(sleep[0])]
assert len(breath) == len(hop) == len(sleep) and len(cushion) > 40
os.makedirs(OUT, exist_ok=True)
for name, img in (("cat-sleep", sleep), ("cat-breath", breath), ("cat-hop", hop)):
    pngio.write(os.path.join(OUT, name + ".png"), img)
CAT_FRAME = (CAT_AT[0] + cx0, CAT_AT[1] + cy0, cx1 - cx0, cy1 - cy0)
print("cat frame", CAT_FRAME)

os.makedirs(OUT, exist_ok=True)
pngio.write(os.path.join(OUT, "room-off.png"), room_off)
pngio.write(os.path.join(OUT, "room.png"), room)
pngio.write(os.path.join(OUT, "chair.png"), chair)
# Full canvas, so the scene source holds every room layer at one size; export.py crops it to the seat.
pngio.write(os.path.join(OUT, "chair_front.png"),
            [[front[y - SEAT[1]][x - SEAT[0]] if SEAT[0] <= x < SEAT[0] + SEAT[2] and SEAT[1] <= y < SEAT[1] + SEAT[3] else CLEAR
              for x in range(W)] for y in range(H)])
pngio.write(os.path.join(OUT, "city-night.png"), city)
pngio.write(os.path.join(OUT, "city-day.png"), city_day)
pngio.write(os.path.join(OUT, "room-day.png"), daylight(room))
pngio.write(os.path.join(OUT, "room-day-off.png"), daylight(room_off))
for p, b in boy.items():
    pngio.write(os.path.join(OUT, f"boy-{p}.png"), [row[bx0:bx1] for row in b[by0:by1]])
with open(os.path.join(OUT, "geometry.json"), "w") as f:
    import json
    json.dump(dict(seat=SEAT, city=CITY), f)
print("seat", SEAT, "city", CITY)
print("room.png and chair.png written to", OUT, "| filled px:", sum(map(sum, near)), "| chair px:", sum(map(sum, mask)))
