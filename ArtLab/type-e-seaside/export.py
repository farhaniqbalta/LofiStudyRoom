#!/usr/bin/env python3
"""Art set E (seaside hut): writes its scene and packs into LoFiRoom/Assets from raw/.
Run from the repo root: python3 ArtLab/type-e-seaside/cut_rooms.py && python3 ArtLab/type-e-seaside/export.py
then launch the app with -artSet E. Registry: docs/ART_SETS.md.
shortcut: packs are written straight from the raw PNGs (no .aseprite sources yet); move them to Aseprite
when the art gets a hand pass, as set D did.
"""
import json, os, random, shutil, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "Tools"))
import pngio
sys.path.insert(0, HERE)
import skin

ASSETS = os.path.join(ROOT, "LoFiRoom", "Assets")
RAW = os.path.join(HERE, "raw")
ART_SET, SCENE, PERSPECTIVE = "E", "SeasideHut01", "seaside-hut-back-v1"
W, H = 320, 240
SAFE = (11, 16, 298, 208)        # x, top, w, h: 298x208 is an exact 8x on the iPad Pro 11" (2388x1668)
SEAT = (100, 148, 56, 70)        # the boy at the round table, a little right of centre, hands on its front edge
BOY_H = 70                       # frame height: room above his head for the stretch's raised arms
VIEW = (57, 32, 205, 140)        # the sea opening; must match cut_rooms.py's scenery crop
CLOCK = (269, 128, 23, 15)       # standing on the right-hand counter (top at row 143), left of the lantern
PET = (178, 194, 32, 24)         # on the rug right of the table (no cat yet)
CHEST = (224, 150, 40, 32)       # the wooden chest: tapping it opens the music player
PANEL_AT = (218, 60)             # the player panel, upper right over the curtain and headland
NOTES_AT = (238, 136)            # top-left of the rising notes, just above the chest
PROV = "Under PixelLab's Terms of Service; job ids in ArtLab/type-e-seaside/prompts.md."

def rect(x, top, w, h):          # top-left image pixels -> manifest (origin bottom-left)
    return dict(x=x, y=H - top - h, w=w, h=h)

def read(name):
    return pngio.read(os.path.join(RAW, name))

def pack(category, folder, frames, manifest):
    """One row of equal frames plus its manifest."""
    d = os.path.join(ASSETS, category, folder)
    os.makedirs(d, exist_ok=True)
    fw, fh = len(frames[0][0]), len(frames[0])
    assert all(len(f[0]) == fw and len(f) == fh for f in frames), f"{folder}: frames differ in size"
    pngio.write(os.path.join(d, "sheet.png"), [sum((f[y] for f in frames), []) for y in range(fh)])
    manifest = dict(id=folder.lower(), type=manifest.pop("type"), packVersion=1, perspective=PERSPECTIVE,
                    sheet="sheet.png", frame=dict(w=fw, h=fh), **manifest)
    json.dump(manifest, open(os.path.join(d, "manifest.json"), "w"), indent=2)

RAIN_FRAMES = 4
RAIN_LAYERS = (dict(colour=(150, 170, 205, 150), spacing=5, length=4, step=6),    # far: short, faint, slow
               dict(colour=(205, 220, 240, 200), spacing=9, length=7, step=11))   # near: long, bright, fast

def rain(w, h):
    """Slanted streaks falling past the open front, looping in RAIN_FRAMES (each layer's period is
    RAIN_FRAMES * step, so frame 0 follows the last seamlessly). No drops on glass: the hut has none."""
    rng = random.Random(5)
    layers = [(l, RAIN_FRAMES * l["step"], [(x + rng.randrange(l["spacing"]), rng.randrange(RAIN_FRAMES * l["step"]))
                                            for x in range(0, w + h // 3, l["spacing"])]) for l in RAIN_LAYERS]
    frames = []
    for f in range(RAIN_FRAMES):
        img = [[(0, 0, 0, 0)] * w for _ in range(h)]
        for l, period, drops in layers:
            for x, y0 in drops:
                for y in range((y0 + f * l["step"]) % period - period, h, period):
                    for k in range(l["length"]):           # one px left every 3 rows
                        if 0 <= y + k < h and 0 <= x - (y + k) // 3 < w:
                            img[y + k][x - (y + k) // 3] = l["colour"]
        frames.append(img)
    return frames

# Scene. Lamp-off rooms are stand-ins (the lit rooms) until they are drawn.
scene_dir = os.path.join(ASSETS, "Scenes", SCENE)
os.makedirs(scene_dir, exist_ok=True)
for phase in ("day", "night"):
    shutil.copyfile(os.path.join(RAW, f"room-{phase}.png"), os.path.join(scene_dir, f"room_{phase}.png"))
pngio.write(os.path.join(scene_dir, "music_panel.png"), skin.panel())
pngio.write(os.path.join(scene_dir, "music_icons.png"), skin.sheet(skin.icons()))
pngio.write(os.path.join(scene_dir, "music_notes.png"), skin.sheet(skin.notes()))
def slot(name):
    x, y, w, h = skin.SLOTS[name]
    return rect(PANEL_AT[0] + x, PANEL_AT[1] + y, w, h)

drops = rain(VIEW[2], VIEW[3])
pngio.write(os.path.join(scene_dir, "rain.png"), [sum((f[y] for f in drops), []) for y in range(VIEW[3])])
window = rect(*VIEW)
anchors = {"window-rect": window, "window-mask": window, "desk-seat": rect(*SEAT), "pet-spot": rect(*PET),
           "clock-slot": rect(*CLOCK), "lamp": dict(x=112, y=H - 165), "computer": dict(x=CHEST[0], y=H - CHEST[1]),
           "music-notes": rect(*NOTES_AT, 12, 15)}
json.dump(dict(id=SCENE.lower(), type="scene", artSet=ART_SET, packVersion=1, perspective=PERSPECTIVE,
               canvas=dict(w=W, h=H), safe=rect(*SAFE), anchors=anchors, room="room_night.png",
               rooms={"night-on": "room_night.png", "night-off": "room_night.png",
                      "day-on": "room_day.png", "day-off": "room_day.png"},
               foreground=[],    # the boy sits in front of the table: nothing in the room covers him
               # waves beside the rain loop: LocalAudio/ocean-waves.mp3, git-ignored (licence in docs/AUDIO.md)
               ambient=dict(file="ocean-waves", name="Waves"),
               rain=dict(sheet="rain.png", frame=dict(w=VIEW[2], h=VIEW[3]), fps=8, anchor="window-rect"),
               # Spotify player: tap the chest ("computer" is the engine's tap role for the music player)
               music=dict(panel="music_panel.png", frame=rect(*PANEL_AT, *skin.PANEL_SIZE),
                          icons=dict(sheet="music_icons.png", frame=dict(w=10, h=10), names=["previous", "play", "pause", "next", "close"]),
                          slots={name: slot(name) for name in skin.SLOTS}, textColor=skin.TEXT_HEX, dimColor=skin.DIM_HEX,
                          notes=dict(sheet="music_notes.png", frame=dict(w=12, h=15), fps=2, anchor="music-notes")),
               hotspots={"computer": rect(*CHEST)},
               # the boy is drawn in neutral light: cool him at night, warm him in the sunset
               actorTints={"night-on": dict(color="#6C74B0", amount=0.35), "night-off": dict(color="#5A5C8C", amount=0.45),
                           "day-on": dict(color="#FFC896", amount=0.15), "day-off": dict(color="#FFC896", amount=0.15)},
               provenance="Art set E, first pass. Room: the user's concept image (kept local, not in the repo), sunset and night "
                          "panels converted by PixelLab image_to_pixelart (faithful), sea opening cut by "
                          "ArtLab/type-e-seaside/cut_rooms.py. " + PROV,
               source="ArtLab/type-e-seaside/raw/"), open(os.path.join(scene_dir, "manifest.json"), "w"), indent=2)

SEA_TOP = 97                     # first sea row in the scenery crop (the horizon)
ISLAND = (120, 103)              # from column 120 rightwards the headland's base reaches down to row 102: water starts at 103
TOWN = (138, 50, 205, 104)       # x0, y0, x1, y1 in the scenery crop: the lit town on the headland
BOAT = {"day": (106, 95, 126, 112), "night": (56, 92, 74, 108)}   # the sailboat and its reflection: kept still
PLANT = {"day": (0, 95, 34, 128), "night": (0, 95, 36, 120)}      # plant leaves hanging over the sea: kept still

def shimmer(name):
    """Three frames of one scenery image. Sea rows slide 1 px, alternate rows opposite ways (glints shimmer);
    at night about a third of the warm town windows dim in frame 2. Only pixels seen through the room's
    opening change, so the post and chime copies baked into the scenery never show."""
    base, room = read(f"scenery-{name}.png"), read(f"room-{name}.png")
    still = (BOAT[name], PLANT[name])
    seen = lambda x, y: (0 <= x < len(base[0]) and room[VIEW[1] + y][VIEW[0] + x][3] == 0
                         and not any(x0 <= x < x1 and y0 <= y < y1 for x0, y0, x1, y1 in still))
    frames = [base]
    for sign in (1, -1):
        f = [row[:] for row in base]
        for y in range(SEA_TOP, len(base)):
            dx = sign if y % 2 else -sign
            for x in range(len(base[0])):
                if x >= ISLAND[0] and y < ISLAND[1]: continue
                if seen(x, y) and seen(x - dx, y):
                    f[y][x] = base[y][x - dx]
        frames.append(f)
    if name == "night":
        f = frames[2]
        for y in range(TOWN[1], TOWN[3]):
            for x in range(TOWN[0], TOWN[2]):
                r, g, b, _ = base[y][x]
                if seen(x, y) and r > 180 and g > 110 and b < 120 and (x * 7 + y * 13) % 3 == 0:
                    f[y][x] = min((base[y + j][x + i] for i, j in ((1, 0), (-1, 0), (0, 1), (0, -1))), key=sum)
    return frames

pack("Scenery", "SeasideView01", shimmer("night") + shimmer("day"), dict(
    type="scenery", anchor="window-rect",
    animations={"night": dict(frames=[0, 1, 0, 2], fps=1.5), "day": dict(frames=[3, 4, 3, 5], fps=1.5)},
    fallbackAnimation="night", phases={"night": "night", "day": "day"},
    provenance="The sea, town and sky from the same converted panels as the room (cut_rooms.py). " + PROV))

once = lambda i, fps, weight, cooldown: dict(frames=[i], fps=fps, loop=False, safeExits=[],
                                             routine=dict(weight=weight, cooldown=cooldown))
def boy(name):                   # 56x56 poses padded on top to BOY_H; the bottom-left anchor keeps them in place
    im = read(name)
    return [[(0, 0, 0, 0)] * len(im[0]) for _ in range(BOY_H - len(im))] + im

# boy-shirt-stretch-big.png: PixelLab drew the stretch about 1.2x too small to fit the raised arms in 56x56;
# it is scaled back up (EPX 2x, then nearest down to 1.2x), its hips lined up with the base pose, on a 56x70 frame.
pack("Characters", "SeasideBoy", [boy(f) for f in ("boy-shirt.png", "boy-shirt-drink.png", "boy-shirt-stretch-big.png", "boy-shirt-rest.png")], dict(
    type="character", anchor="desk-seat",
    animations={"study": dict(frames=[0], fps=1), "drink": once(1, 0.4, 3, 300),
                "stretch": once(2, 0.33, 2, 600), "rest": once(3, 0.125, 1, 900)},
    fallbackAnimation="study",
    provenance="PixelLab create_image_pixen (desk erased by hand) and edit_image_pixen poses recoloured to its palette. " + PROV))
pack("Characters", "SeasideBoyShirtless", [boy("boy-shirtless.png")], dict(
    type="character", anchor="desk-seat",
    animations={"study": dict(frames=[0], fps=1)}, fallbackAnimation="study",
    provenance="PixelLab edit_image_pixen of the shirt boy. Poses not drawn yet. " + PROV))

# The clock: set A's digit shapes in lantern amber on a teak bezel drawn by skin.py (same 23x15 size and slots).
src, dst = os.path.join(ASSETS, "Clocks", "RetroDigital01"), os.path.join(ASSETS, "Clocks", "SeasideClock")
os.makedirs(dst, exist_ok=True)
manifest = json.load(open(os.path.join(src, "manifest.json")))
glyphs = [[skin.AMBER_LIT if p[3] else p for p in row] for row in pngio.read(os.path.join(src, "sheet.png"))]
pngio.write(os.path.join(dst, "sheet.png"), glyphs)
pngio.write(os.path.join(dst, "bezel.png"), skin.clock_bezel())
manifest.update(id="seasideclock", perspective=PERSPECTIVE,
                provenance="Set A's RetroDigital01 digit shapes recoloured amber; teak bezel drawn by ArtLab/type-e-seaside/skin.py.")
json.dump(manifest, open(os.path.join(dst, "manifest.json"), "w"), indent=2)
print("exported scene", SCENE)
