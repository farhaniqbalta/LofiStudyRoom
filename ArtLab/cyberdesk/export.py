#!/usr/bin/env python3
"""Art-direction spike: exports the cyber-desk scene and its packs from the .aseprite sources into LoFiRoom/Assets.
Run from the repo root: python3 ArtLab/cyberdesk/export.py   (then launch the app with -scene StudyRoomCyber01)
The scene folder name sorts after StudyRoom01 on purpose, so the default scene does not change."""
import json, os, shutil, subprocess, sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.join(HERE, "..", "..")
sys.path.insert(0, os.path.join(ROOT, "Tools"))
import aseprite_export

ASSETS = os.path.join(ROOT, "LoFiRoom", "Assets")
SCENE, PERSPECTIVE = "StudyRoomCyber01", "cyber-desk-side-v1"
W, H = 480, 352
SEAT = (272, 136, 146, 204)      # must match cut_layers.py and the CyberBoy canvas

def rect(x, top, w, h):          # top-left image pixels -> manifest (origin bottom-left)
    return dict(x=x, y=H - top - h, w=w, h=h)

def layer(name, out, crop=None):
    cmd = [aseprite_export.ASEPRITE, "-b", "--layer", name, os.path.join(HERE, SCENE + ".aseprite")]
    if crop: cmd += ["--crop", ",".join(map(str, crop))]
    subprocess.run(cmd + ["--save-as", out], check=True, stdout=subprocess.DEVNULL)

scene_dir = os.path.join(ASSETS, "Scenes", SCENE)
os.makedirs(scene_dir, exist_ok=True)
layer("room", os.path.join(scene_dir, "room.png"))
layer("chair_front", os.path.join(scene_dir, "chair_front.png"), SEAT)
pet = rect(96, 302, 37, 28)
window = rect(36, 31, 88, 224)
anchors = {"window-rect": window, "window-mask": window, "desk-seat": rect(*SEAT), "pet-spot": pet,
           "clock-slot": rect(201, 200, 23, 15), "lamp": dict(x=215, y=H - 150), "computer": dict(x=300, y=H - 165)}
with open(os.path.join(scene_dir, "manifest.json"), "w") as f:
    json.dump(dict(id=SCENE.lower(), type="scene", packVersion=1, perspective=PERSPECTIVE,
                   canvas=dict(w=W, h=H), safe=dict(x=14, y=12, w=452, h=328), anchors=anchors, room="room.png",
                   foreground=[dict(image="chair_front.png", anchor="desk-seat")],
                   hotspots={"pet": pet, "window": window, "lamp": rect(162, 128, 70, 98), "computer": rect(236, 140, 102, 75)},
                   provenance="Art-direction spike, not production art. PixelLab create_image_pixen job "
                              "6a15ba72-3d76-4db9-bbbc-d08f2fe3a58f; glass keyed out and chair-front layer traced by "
                              "ArtLab/cyberdesk/cut_layers.py; layers held in ArtLab/cyberdesk/StudyRoomCyber01.aseprite.",
                   source="ArtLab/cyberdesk/StudyRoomCyber01.aseprite"), f, indent=2)

for name in ("CyberBoy", "CyberCat", "CyberCity01"):
    aseprite_export.export(os.path.join(HERE, name + ".aseprite"), ASSETS)

# The clock skin has no .aseprite source yet: reuse the existing one under the new perspective tag.
src, dst = os.path.join(ASSETS, "Clocks", "RetroDigital01"), os.path.join(ASSETS, "Clocks", "CyberClock")
shutil.copytree(src, dst, dirs_exist_ok=True)
manifest = json.load(open(os.path.join(dst, "manifest.json")))
manifest.update(id="cyberclock", perspective=PERSPECTIVE, provenance="Copy of Clocks/RetroDigital01 for the art-direction spike.")
json.dump(manifest, open(os.path.join(dst, "manifest.json"), "w"), indent=2)
print("exported scene", SCENE)
