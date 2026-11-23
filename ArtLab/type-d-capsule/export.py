#!/usr/bin/env python3
"""Art set D (capsule desk): exports its scene and packs from the .aseprite sources into LoFiRoom/Assets.
Run from the repo root: python3 ArtLab/type-d-capsule/export.py   (then launch the app with -artSet D)
Sources: cut_layers.py makes layers/ from raw/; make_source.lua turned those into the .aseprite files once.
Edit the .aseprite files from now on; re-running make_source.lua overwrites them. Registry: docs/ART_SETS.md."""
import json, os, shutil, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "Tools"))
import aseprite_export

ASSETS = os.path.join(ROOT, "LoFiRoom", "Assets")
ART_SET, SCENE, PERSPECTIVE = "D", "CapsuleDesk01", "capsule-desk-side-v1"
W, H = 480, 352
SEAT = (206, 157, 141, 181)      # x, top, w, h: the boy's frame; must match cut_layers.py (layers/geometry.json)
CITY = (14, 14, 220, 224)        # the city frame behind the glass; must match cut_layers.py

def rect(x, top, w, h):          # top-left image pixels -> manifest (origin bottom-left)
    return dict(x=x, y=H - top - h, w=w, h=h)

def frame(tag, out, crop=None):  # one tagged frame of the scene source
    cmd = [aseprite_export.ASEPRITE, "-b", "--tag", tag, os.path.join(HERE, SCENE + ".aseprite")]
    if crop: cmd += ["--crop", ",".join(map(str, crop))]
    subprocess.run(cmd + ["--save-as", out], check=True, stdout=subprocess.DEVNULL)

scene_dir = os.path.join(ASSETS, "Scenes", SCENE)
os.makedirs(scene_dir, exist_ok=True)
frame("room", os.path.join(scene_dir, "room.png"))
frame("room_off", os.path.join(scene_dir, "room_off.png"))
frame("chair_front", os.path.join(scene_dir, "chair_front.png"), SEAT)
pet, window = rect(116, 258, 24, 20), rect(*CITY)
anchors = {"window-rect": window, "window-mask": window, "desk-seat": rect(*SEAT), "pet-spot": pet,
           "clock-slot": rect(216, 207, 23, 15), "lamp": dict(x=262, y=H - 185), "computer": dict(x=200, y=H - 220)}
with open(os.path.join(scene_dir, "manifest.json"), "w") as f:
    json.dump(dict(id=SCENE.lower(), type="scene", artSet=ART_SET, packVersion=1, perspective=PERSPECTIVE,
                   canvas=dict(w=W, h=H), safe=dict(x=14, y=12, w=452, h=328), anchors=anchors, room="room.png",
                   rooms={"night-off": "room_off.png", "day-off": "room_off.png"},
                   foreground=[dict(image="chair_front.png", anchor="desk-seat")],
                   hotspots={"pet": pet, "window": window, "lamp": rect(238, 160, 48, 60), "computer": rect(163, 195, 75, 52)},
                   provenance="Art set D, first pass. Room: PixelLab create_image_pixen job 50537b9f-f1dc-4160-a134-397bc933d340 "
                              "(room 3a), chair painted out by the user, glass keyed out, the user's boy image's chair added and "
                              "lamp-off from edit_image_pixen job 65b3e775-34f4-429d-94d5-f31c6c97d965, all by "
                              "ArtLab/type-d-capsule/cut_layers.py; layers held in ArtLab/type-d-capsule/CapsuleDesk01.aseprite.",
                   source="ArtLab/type-d-capsule/CapsuleDesk01.aseprite"), f, indent=2)

for name in ("CapsuleBoy", "CapsuleCat", "CapsuleCityNight"):
    aseprite_export.export(os.path.join(HERE, name + ".aseprite"), ASSETS)

# The clock skin has no .aseprite source yet: reuse set A's under set D's perspective tag.
src, dst = os.path.join(ASSETS, "Clocks", "RetroDigital01"), os.path.join(ASSETS, "Clocks", "CapsuleClock")
shutil.copytree(src, dst, dirs_exist_ok=True)
manifest = json.load(open(os.path.join(dst, "manifest.json")))
manifest.update(id="capsuleclock", perspective=PERSPECTIVE, provenance="Copy of Clocks/RetroDigital01 for art set D.")
json.dump(manifest, open(os.path.join(dst, "manifest.json"), "w"), indent=2)
print("exported scene", SCENE)
