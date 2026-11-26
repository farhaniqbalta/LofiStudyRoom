"""Room E from the user's concept image: cut the sea opening out of the night and sunset rooms.

Input: raw/px-night-faithful.png and raw/px-sunset-faithful.png (PixelLab image_to_pixelart, 320x240).
Writes raw/room-night.png and raw/room-day.png (320x240, transparent where the background goes).
Coordinates below were picked on the earlier 313x234 shrink; U() maps them onto the 320x240 grid.
The opening is found by flood fill from sky/sea seeds (neighbour colour step <= T), then small
enclosed islands (moon, stars, town lights, boat) are filled. The hanging shell chime gets a tight
tolerance so its string and shells stay. The day cut also takes the night cut where the day pixel is not a warm object
(the panels line up: checked offset 0,0).
shortcut: seeds and boxes are hand-picked for this one image; redo them if the source changes.
"""
import os, sys
from collections import deque
HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, "..", "..", "Tools"))
import pngio

SX, SY = 320 / 313, 240 / 234
U = lambda x, y: (round(x * SX), round(y * SY))     # old grid -> new grid
O = lambda x, y: (x / SX, y / SY)                   # new grid -> old grid, for the box tests
BOX = (*U(40, 30), *U(270, 168))                    # x0, y0, x1, y1 around the opening
CHIME = lambda x, y: (lambda a, b: 86 <= a <= 101 and 42 <= b <= 106)(*O(x, y))
HILL = lambda x, y: (lambda a, b: 195 <= a < 260 and 85 <= b < 136)(*O(x, y))   # cliff and town: warm in the day panel
SKY = [(100, 60), (200, 50), (230, 90), (110, 100), (180, 130), (220, 125), (160, 140), (100, 135), (100, 80), (120, 120)]
SEEDS = {
    "night": (32, SKY + [(200, 160)], lambda c: c[2] > c[0] + 10),   # night sky and sea are blue; wood is warm
    "sunset": (30, SKY + [(225, 105), (210, 115), (240, 95), (200, 120), (235, 112), (150, 150), (100, 150), (230, 152), (80, 148), (180, 152), (210, 155)], lambda c: True),
}

inb = lambda x, y: BOX[0] <= x < BOX[2] and BOX[1] <= y < BOX[3]
step = lambda a, b: max(abs(a[i] - b[i]) for i in range(3))

def flood(img, T, seeds, ok):
    cut, q = set(seeds), deque(seeds)
    while q:
        x, y = q.popleft()
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if inb(nx, ny) and (nx, ny) not in cut and ok(img[ny][nx]) and step(img[y][x], img[ny][nx]) <= (8 if CHIME(nx, ny) else T):
                cut.add((nx, ny)); q.append((nx, ny))
    return cut

def fill_islands(cut, limit=2500):
    seen = set()
    for y in range(BOX[1], BOX[3]):
        for x in range(BOX[0], BOX[2]):
            if (x, y) in cut or (x, y) in seen: continue
            comp, i, edge = [(x, y)], 0, False
            seen.add((x, y))
            while i < len(comp):
                cx, cy = comp[i]; i += 1
                for n in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)):
                    if not inb(*n): edge = True
                    elif n not in cut and n not in seen: seen.add(n); comp.append(n)
            if not edge and len(comp) < limit and not any(CHIME(*c) for c in comp):
                cut.update(comp)
    return cut

def drop_specks(cut, img, limit=40):
    """Opaque bits left inside the opening (sun glints, wave crests, stray leaves) that touch no box edge
    and are smaller than limit go with the background; the chime is left alone."""
    seen = set()
    for y in range(BOX[1], BOX[3]):
        for x in range(BOX[0], BOX[2]):
            if (x, y) in cut or (x, y) in seen: continue
            comp, i, edge = [(x, y)], 0, False
            seen.add((x, y))
            while i < len(comp):
                cx, cy = comp[i]; i += 1
                for n in ((cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1), (cx + 1, cy + 1), (cx - 1, cy - 1), (cx + 1, cy - 1), (cx - 1, cy + 1)):
                    if not inb(*n): edge = True
                    elif n not in cut and n not in seen: seen.add(n); comp.append(n)
                if len(comp) > limit: break
            if not edge and len(comp) <= limit and not any(CHIME(*c) for c in comp):
                cut.update(comp)
    return cut

def mask(name):
    img = pngio.read(os.path.join(HERE, "raw", f"px-{name}-faithful.png"))
    T, seeds, ok = SEEDS[name]
    seeds = [U(*p) for p in seeds]
    return img, fill_islands(flood(img, T, seeds, ok))

night, nmask = mask("night")
day, dmask = mask("sunset")
# the panels line up, so the night cut (cleaner: blue against warm wood) also cuts the day panel,
# except where the day pixel is a warm object (fruit, vines, wood): r well above b.
dmask = fill_islands(dmask | {(x, y) for x, y in nmask if HILL(x, y) or day[y][x][0] <= day[y][x][2] + 40})
nmask, dmask = drop_specks(nmask, night), drop_specks(dmask, day)
assert len(nmask) > 15000 and len(dmask) > 15000, "opening cut too small: seeds missed"
for img, m, out in ((night, nmask, "room-night.png"), (day, dmask, "room-day.png")):
    cutimg = [[(0, 0, 0, 0) if (x, y) in m else p for x, p in enumerate(row)] for y, row in enumerate(img)]
    pngio.write(os.path.join(HERE, "raw", out), cutimg)
    print(out, "cut", len(m))

# Background (scenery): the same panel cropped to the opening's bounding box. It sits under the room,
# so anything the room still covers (post, chime, plant) is hidden and needs no repainting.
both = nmask | dmask
x0, x1 = min(x for x, _ in both), max(x for x, _ in both) + 1
y0, y1 = min(y for _, y in both), max(y for _, y in both) + 1
for img, out in ((night, "scenery-night.png"), (day, "scenery-day.png")):
    pngio.write(os.path.join(HERE, "raw", out), [row[x0:x1] for row in img[y0:y1]])
H = len(night)
print(f"scenery {x1 - x0}x{y1 - y0}, top-left ({x0},{y0}); window-rect anchor (origin bottom-left): x {x0}, y {H - y1}, w {x1 - x0}, h {y1 - y0}")
