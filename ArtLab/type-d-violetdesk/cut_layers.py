#!/usr/bin/env python3
"""Art set D: turns the user's hand edit of room 3a into clean layer PNGs (stdlib only).
Run from the repo root: python3 ArtLab/type-d-violetdesk/cut_layers.py

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
PANES = [[(4, 15), (92, 33), (92, 238), (4, 238)],          # left, its left edge is the curtain (kept by colour)
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

os.makedirs(OUT, exist_ok=True)
pngio.write(os.path.join(OUT, "room.png"), room)
pngio.write(os.path.join(OUT, "chair.png"), chair)
print("room.png and chair.png written to", OUT, "| filled px:", sum(map(sum, near)), "| chair px:", sum(map(sum, mask)))
