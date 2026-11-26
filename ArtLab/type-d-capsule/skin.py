"""Art set D's script-drawn extras (stdlib only): rain on the glass and the music player skin, every colour taken
from room 3a (indigo walls, teal glass and neon, amber lamp). Adapted from set A's Tools/build_art.py, which runs
on import and so cannot be shared. Used by export.py."""
import random

CLEAR = (0, 0, 0, 0)

# ---------- rain: two depths plus beads on the glass; each layer repeats every FRAMES * step rows, so the loop has no seam
FRAMES = 6
LAYERS = [dict(spacing=3, length=2, step=6, colour=(110, 170, 180, 90)),     # far: short, faint, slow
          dict(spacing=9, length=6, step=16, colour=(190, 238, 238, 170))]   # near: long, bright, fast
BEAD_C, BEAD_HI = (107, 213, 211, 120), (220, 250, 250, 200)

def rain(w, h):
    rng = random.Random(7)
    beads = [(rng.randrange(2, w - 2), rng.randrange(2, h - 2)) for _ in range(14)]
    layers = []
    for layer in LAYERS:
        period = FRAMES * layer["step"]
        layers.append((layer, period, [(x + rng.randrange(layer["spacing"]), rng.randrange(period)) for x in range(2, w - 2, layer["spacing"])]))
    frames = []
    for f in range(FRAMES):
        img = [[CLEAR] * w for _ in range(h)]
        for layer, period, drops in layers:
            for x, y0 in drops:
                for y in range((y0 + f * layer["step"]) % period - period, h, period):
                    for k in range(layer["length"]):  # slanted streak: one px left every 3 rows
                        if 0 <= y + k < h and 0 <= x - k // 3 < w:
                            img[y + k][x - k // 3] = layer["colour"]
        for x, y in beads:
            for dx, dy in ((0, 0), (1, 0), (0, 1), (1, 1)):
                img[y + dy][x + dx] = BEAD_C
            img[y][x] = BEAD_HI
        frames.append(img)
    return frames

# ---------- music skin: a small wall tablet, indigo casing with a teal edge like the room's neon tube
CASING = (136, 66)
SHADOW = 2
PANEL_SIZE = (CASING[0] + SHADOW, CASING[1] + SHADOW)
OUTLINE, BODY, BODY_HI, BODY_LO = (0, 0, 0, 255), (47, 38, 59, 255), (73, 88, 113, 255), (26, 22, 43, 255)  # black like the room's outlines
LANTERN = (233, 193, 136, 255)   # the paper lantern, up and to the left, catches the top edge
GLOW, AMBER = (107, 213, 211, 255), (233, 193, 136, 255)
WELL, SCREEN, SCAN = (15, 13, 27, 255), (26, 22, 43, 255), (32, 28, 52, 255)
SHADOW_C = (0, 0, 0, 90)
ICON_C, ICON_SHADOW_C = (220, 246, 244, 255), (15, 13, 27, 255)
TEXT_HEX, DIM_HEX = "#DCF6F4", "#6BD5D3"
# x, y, w, h inside the panel, top-left based
# The action label's font scales with the slot height, so a 12 px slot fits "Resume in Spotify" in 78 px.
SLOTS = dict(artwork=(5, 5, 44, 44), attribution=(5, 51, 42, 12), title=(54, 5, 66, 12), artist=(54, 18, 76, 10),
             previous=(54, 33, 16, 16), toggle=(74, 33, 16, 16), next=(94, 33, 16, 16), close=(123, 4, 8, 8),
             message=(54, 5, 76, 26), action=(54, 35, 78, 12))

def panel():
    cw, ch = CASING
    pw, ph = PANEL_SIZE
    img = [[CLEAR] * pw for _ in range(ph)]
    def fill(x0, y0, x1, y1, c):  # inclusive corners
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                img[y][x] = c
    fill(SHADOW, SHADOW, pw - 1, ph - 1, SHADOW_C)
    fill(0, 0, cw - 1, ch - 1, OUTLINE)
    fill(1, 1, cw - 2, ch - 2, BODY)
    for x in range(3, cw - 3, 4):                                           # faint brushed texture
        for y in range(3, ch - 3):
            if (x + y) % 7 == 0:
                img[y][x] = BODY_LO
    fill(1, 1, cw - 2, 1, BODY_HI); fill(1, 1, 1, ch - 2, BODY_HI)          # raised: light top-left
    for x in range(2, cw // 2, 2):                                          # lantern light on the top edge, fading right
        img[1][x] = LANTERN
    fill(1, ch - 2, cw - 2, ch - 2, BODY_LO); fill(cw - 2, 1, cw - 2, ch - 2, BODY_LO)
    for x in range(8, cw - 8, 2):                                           # teal neon strip along the bottom
        img[ch - 1][x] = GLOW
    for x, y in ((0, 0), (cw - 1, 0), (0, ch - 1), (cw - 1, ch - 1)):     # rounded corners
        img[y][x] = CLEAR
    fill(4, 4, 49, 49, WELL)                                                # cover well
    fill(52, 3, cw - 4, ch - 4, SCREEN)                                     # screen behind text and buttons
    for y in range(4, ch - 4, 2):
        fill(53, y, cw - 5, y, SCAN)
    fill(54, 30, cw - 6, 30, BODY)                                          # divider: track text / controls
    img[ch - 8][cw - 8] = AMBER; img[ch - 8][cw - 11] = GLOW                # status lights
    return img

def _paste(canvas, rows, x, y):
    for j, row in enumerate(rows):
        for i, c in enumerate(row):
            if c == "X":
                canvas[y + j][x + i] = ICON_C

def _icon(*parts):
    canvas = [[CLEAR] * 16 for _ in range(16)]
    for rows, x, y in parts:
        _paste(canvas, rows, x, y)
    for y in range(15, 0, -1):          # 1 px drop shadow down-right
        for x in range(15, 0, -1):
            if canvas[y][x] == CLEAR and canvas[y - 1][x - 1] == ICON_C:
                canvas[y][x] = ICON_SHADOW_C
    return canvas

TRI_R = ["X....", "XX...", "XXX..", "XXXX.", "XXXXX", "XXXX.", "XXX..", "XX...", "X...."]
PLAY = ["X......", "XX.....", "XXX....", "XXXX...", "XXXXX..", "XXXXXX.", "XXXXX..", "XXXX...", "XXX....", "XX.....", "X......"]
CLOSE = ["".join("X" if abs(x - y) <= 1 or abs(x - (7 - y)) <= 1 else "." for x in range(8)) for y in range(8)]

def icons():
    nxt = _icon((TRI_R, 3, 3), (TRI_R, 8, 3), (["XX"] * 9, 13, 3))
    return [[row[::-1] for row in nxt], _icon((PLAY, 4, 2)), _icon((["XXX"] * 11, 4, 2), (["XXX"] * 11, 9, 2)), nxt,
            _icon((CLOSE, 4, 4))]  # previous, play, pause, next, close

def _note(canvas, x, y, colour):
    for j, row in enumerate(("..XXX", "..X.X", "..X..", "..X..", "..X..", ".XX..", "XXX..", ".X...")):
        for i, c in enumerate(row):
            if c == "X" and 0 <= y + j < 24 and 0 <= x + i < 20:
                canvas[y + j][x + i] = colour

def notes():
    frames = []
    for f in range(4):
        canvas = [[CLEAR] * 20 for _ in range(24)]
        _note(canvas, 3 + (f % 2) * 2, 16 - 4 * f, AMBER)                 # amber note rises and sways
        _note(canvas, 12 - (f % 2) * 2, 16 - 4 * ((f + 2) % 4), GLOW)     # teal note half a loop behind
        frames.append(canvas)
    return frames

def sheet(frames):
    return [sum((f[y] for f in frames), []) for y in range(len(frames[0]))]

assert all(x + w <= CASING[0] - 2 and y + h <= CASING[1] - 2 for x, y, w, h in SLOTS.values()), "slots inside the casing"
