#!/usr/bin/env python3
"""Art set B (cyberpunk side desk): cuts the raw PixelLab images into layer PNGs that are then imported into the
.aseprite sources (stdlib only). Run from the repo root: python3 ArtLab/type-b-cyberdesk/cut_layers.py
Coordinates are room pixels, top-left based, read off Aseprite's ruler view."""
import os, sys
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "Tools"))
import pngio
from cutout import figure, polygon

RAW, OUT = os.path.join(HERE, "raw"), os.path.join(HERE, "layers")
CLEAR = (0, 0, 0, 0)
CROP = (264, 128)                       # where the 192x224 crop sent to PixelLab sits in the room
SEAT = (272, 136, 146, 204)             # character frame: x, top, w, h (bottom stops at the safe area)
WINDOW = (36, 31, 88, 224)

# In front of the character: the chair back and the near armrest with its support.
CHAIR_FRONT = [
    [(370, 207), (413, 203), (415, 210), (415, 296), (404, 298), (390, 290), (360, 292), (358, 270), (362, 244), (366, 220)],
    [(297, 253), (318, 252), (338, 258), (344, 262), (344, 268), (330, 268), (300, 262), (296, 258)],
    [(322, 266), (346, 268), (350, 290), (326, 290)],
]
# Loose outline of the seated figure; unchanged background inside it is dropped by `figure`.
ENVELOPE = [(338, 146), (352, 138), (384, 136), (400, 144), (405, 164), (404, 190), (398, 200), (414, 206), (416, 298), (404, 300),
            (350, 300), (322, 304), (320, 326), (318, 340), (272, 340), (272, 326), (286, 318), (288, 264), (292, 250),
            (300, 244), (318, 236), (322, 224), (300, 234), (288, 226), (288, 214), (306, 212), (330, 214), (340, 200),
            (336, 180), (338, 160)]

room = pngio.read(os.path.join(RAW, "room_raw.png"))
W, H = len(room[0]), len(room)

# 1. Room with the green glass keyed out (only inside the window, the monitors have green text).
keyed = [list(row) for row in room]
wx, wy, ww, wh = WINDOW
for y in range(wy, wy + wh):
    for x in range(wx, wx + ww):
        r, g, b, _ = keyed[y][x]
        if g > 150 and r < 170 and b < 130 and g > r + 40:
            keyed[y][x] = CLEAR
pngio.write(os.path.join(OUT, "room.png"), keyed)

# 2. Chair pieces in front of the character, copied from the untouched room.
chair = set().union(*(polygon(p) for p in CHAIR_FRONT))
front = [[room[y][x] if (x, y) in chair else CLEAR for x in range(W)] for y in range(H)]
pngio.write(os.path.join(OUT, "chair_front.png"), front)

# 3. The character: what the edit changed inside the envelope, with the body continued behind the chair.
cx, cy = CROP
after_crop = pngio.read(os.path.join(RAW, "boy_edit_raw.png"))
after = [list(row) for row in room]
for j, row in enumerate(after_crop):
    after[cy + j][cx:cx + len(row)] = row
shape = figure(room, after, polygon(ENVELOPE), threshold=2)  # strict: dark clothes are close to the dark room
body = [[after[y][x] if (x, y) in shape else CLEAR for x in range(W)] for y in range(H)]
visible = shape - chair
for x, y in chair & polygon(ENVELOPE):
    near = [(abs(d), body[y + dy * d][x + dx * d]) for dx, dy in ((1, 0), (0, 1)) for d in range(-60, 61)
            if (x + dx * d, y + dy * d) in visible]
    if near:
        body[y][x] = min(near, key=lambda n: n[0])[1]
sx, sy, sw, sh = SEAT
pngio.write(os.path.join(OUT, "boy_body.png"), pngio.crop(body, sx, sy, sw, sh))
print("layers written; character pixels:", sum(1 for row in pngio.crop(body, sx, sy, sw, sh) for p in row if p[3]))
