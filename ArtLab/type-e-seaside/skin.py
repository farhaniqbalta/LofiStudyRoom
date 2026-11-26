"""Art set E's script-drawn extras (stdlib only): the teak music panel (opened by tapping the chest), its icons and
notes, and the in-world clock's bezel. Colours from the hut: teak wood, lantern amber, cream linen. The layout is set D's
(ArtLab/type-d-capsule/skin.py) at 0.625 scale: set E shows at 8x on the iPad against D's 5x, so the text comes
out the same size on screen. Used by export.py."""

CLEAR = (0, 0, 0, 0)
OUTLINE = (38, 22, 20, 255)
WOOD, WOOD_HI, WOOD_LO = (122, 74, 46, 255), (171, 112, 66, 255), (78, 45, 32, 255)
LANTERN = (246, 196, 120, 255)
SCREEN, SCAN = (36, 27, 32, 255), (44, 33, 38, 255)
CREAM, AMBER = (243, 226, 196, 255), (217, 160, 102, 255)
SHADOW_C = (0, 0, 0, 90)
TEXT_HEX, DIM_HEX = "#F3E2C4", "#D9A066"

# ---------- the in-world clock: a raised teak frame, dark warm screen, amber digits (23x15, set A's slots)
AMBER_LIT = (255, 186, 92, 255)

def clock_bezel():
    w, h = 23, 15
    img = [[OUTLINE] * w for _ in range(h)]
    for y in range(1, h - 1):
        for x in range(1, w - 1):
            img[y][x] = WOOD
    for x in range(1, w - 1): img[1][x] = WOOD_HI; img[h - 2][x] = WOOD_LO    # lit top, shaded bottom
    for y in range(1, h - 1): img[y][1] = WOOD_HI; img[y][w - 2] = WOOD_LO
    for x in range(2, w // 2, 2): img[1][x] = LANTERN                          # lantern glint, as on the panel
    for y in range(3, h - 3):                                                  # screen behind the digits (rows 3-11)
        for x in range(2, w - 2):
            img[y][x] = SCREEN
    for x, y in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):            # rounded corners
        img[y][x] = CLEAR
    return img

# ---------- the player panel
CASING = (86, 42)
SHADOW = 1
PANEL_SIZE = (CASING[0] + SHADOW, CASING[1] + SHADOW)
# x, y, w, h inside the panel, top-left based (set D's layout x 0.625)
SLOTS = dict(artwork=(3, 3, 28, 28), attribution=(3, 32, 27, 7), title=(34, 3, 42, 8), artist=(34, 11, 48, 6),
             previous=(34, 21, 10, 10), toggle=(46, 21, 10, 10), next=(58, 21, 10, 10), close=(76, 2, 8, 8),
             message=(34, 3, 48, 16), action=(34, 22, 49, 8))

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
    fill(1, 1, cw - 2, ch - 2, WOOD)
    for y in range(3, ch - 3, 3):                                           # wood grain
        for x in range(2, cw - 2):
            if (x * 3 + y * 5) % 11 == 0:
                img[y][x] = WOOD_LO
    fill(1, 1, cw - 2, 1, WOOD_HI); fill(1, 1, 1, ch - 2, WOOD_HI)          # raised: light top-left
    for x in range(2, cw // 2, 2):                                          # lantern light on the top edge
        img[1][x] = LANTERN
    fill(1, ch - 2, cw - 2, ch - 2, WOOD_LO); fill(cw - 2, 1, cw - 2, ch - 2, WOOD_LO)
    for x, y in ((0, 0), (cw - 1, 0), (0, ch - 1), (cw - 1, ch - 1)):     # rounded corners
        img[y][x] = CLEAR
    fill(2, 2, 31, 31, OUTLINE)                                             # cover well
    fill(33, 2, cw - 4, ch - 4, SCREEN)                                     # screen behind text and buttons
    for y in range(3, ch - 4, 2):
        fill(34, y, cw - 5, y, SCAN)
    fill(34, 19, cw - 6, 19, WOOD_LO)                                       # divider: track text / controls
    img[ch - 5][cw - 6] = AMBER                                             # status light
    return img

# ---------- icons, 10x10
ICON_C, ICON_SHADOW_C = CREAM, OUTLINE

def _icon(rows):
    canvas = [[CLEAR] * 10 for _ in range(10)]
    for j, row in enumerate(rows):
        for i, c in enumerate(row):
            if c == "X":
                canvas[1 + j][1 + i] = ICON_C
    for y in range(9, 0, -1):          # 1 px drop shadow down-right
        for x in range(9, 0, -1):
            if canvas[y][x] == CLEAR and canvas[y - 1][x - 1] == ICON_C:
                canvas[y][x] = ICON_SHADOW_C
    return canvas

NEXT = ["X..X..XX", "XX.XX.XX", "XXXXXXXX", "XX.XX.XX", "X..X..XX"]
PLAY = ["X....", "XX...", "XXX..", "XXXX.", "XXXXX", "XXXX.", "XXX..", "XX...", "X...."]
PAUSE = ["XX.XX"] * 7
CLOSE = ["X....X", ".X..X.", "..XX..", "..XX..", ".X..X.", "X....X"]

def icons():
    nxt = _icon([""] * 2 + NEXT)
    prev = _icon([""] * 2 + [row[::-1] for row in NEXT])
    return [prev, _icon(["." + r for r in PLAY]), _icon([""] + [".." + r for r in PAUSE]), nxt, _icon(CLOSE)]  # previous, play, pause, next, close

# ---------- notes rising from the chest, 12x15
def _note(canvas, x, y, colour):
    for j, row in enumerate(("..XX", "..X.", "..X.", ".XX.", "XXX.", ".X..")):
        for i, c in enumerate(row):
            if c == "X" and 0 <= y + j < 15 and 0 <= x + i < 12:
                canvas[y + j][x + i] = colour

def notes():
    frames = []
    for f in range(4):
        canvas = [[CLEAR] * 12 for _ in range(15)]
        _note(canvas, 1 + (f % 2), 9 - 3 * f, AMBER)                        # amber note rises and sways
        _note(canvas, 7 - (f % 2), 9 - 3 * ((f + 2) % 4), CREAM)            # cream note half a loop behind
        frames.append(canvas)
    return frames

def sheet(frames):
    return [sum((f[y] for f in frames), []) for y in range(len(frames[0]))]

assert len(clock_bezel()) == 15 and len(clock_bezel()[0]) == 23
