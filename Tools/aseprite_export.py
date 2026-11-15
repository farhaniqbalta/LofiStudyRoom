#!/usr/bin/env python3
"""Exports one .aseprite source as a sprite pack: <out>/<Category>/<Name>/{sheet.png, manifest.json} (stdlib only).
Run: python3 Tools/aseprite_export.py ArtLab/aseprite/OrangeCatAse.aseprite [out root, default: <source folder>/out]

Aseprite gives the sheet (one row, every frame, in order), the frame size and one animation per tag
(frames = the tag's range, fps = 1000 / frame duration). Everything Aseprite cannot hold comes from the
sidecar <Name>.pack.json next to the source: category, type, perspective, anchor, fallbackAnimation, provenance,
and per-animation fields (routine, onTap, loop, safeExits, or explicit frames / fps, which win over the tag)."""
import json, os, subprocess, sys, tempfile

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
ASEPRITE = os.environ.get("ASEPRITE_PATH", "/Applications/Aseprite.app/Contents/MacOS/aseprite")

def export(source, out_root=None):
    name = os.path.splitext(os.path.basename(source))[0]
    side = json.load(open(os.path.splitext(source)[0] + ".pack.json"))
    folder = os.path.join(out_root or os.path.join(os.path.dirname(source), "out"), side["category"], name)
    manifest_path = os.path.join(folder, "manifest.json")
    rel_source = os.path.relpath(source, ROOT)
    if os.path.exists(manifest_path):  # never replace a pack that some other pipeline made
        assert json.load(open(manifest_path)).get("source") == rel_source, f"{folder} holds a pack not exported from {rel_source}"
    os.makedirs(folder, exist_ok=True)

    with tempfile.TemporaryDirectory() as tmp:
        data_path = os.path.join(tmp, "data.json")
        subprocess.run([ASEPRITE, "-b", source, "--sheet-type", "horizontal", "--sheet", os.path.join(folder, "sheet.png"),
                        "--data", data_path, "--format", "json-array", "--list-tags"], check=True, stdout=subprocess.DEVNULL)
        data = json.load(open(data_path))
    frames = data["frames"]
    w, h = frames[0]["sourceSize"]["w"], frames[0]["sourceSize"]["h"]
    assert data["meta"]["size"] == {"w": w * len(frames), "h": h}, "sheet is not one row of equal frames"

    animations = {}
    for tag in data["meta"]["frameTags"]:
        assert tag["direction"] == "forward", f"tag '{tag['name']}': only forward tags map to frames; list frames in the sidecar instead"
        indices = list(range(tag["from"], tag["to"] + 1))
        durations = {frames[i]["duration"] for i in indices}
        animations[tag["name"]] = dict(frames=indices, **({"fps": 1000 / durations.pop()} if len(durations) == 1 else {}))
    for anim, fields in side.get("animations", {}).items():
        animations[anim] = {**animations.get(anim, {}), **fields}

    scenes = os.path.join(ROOT, "LoFiRoom", "Assets", "Scenes")
    scene = json.load(open(os.path.join(scenes, side.get("scene") or sorted(os.listdir(scenes))[0], "manifest.json")))
    # The same rules as SpritePack.problems(), so a bad export fails here and not on the iPad.
    problems = []
    if side["perspective"] != scene["perspective"]: problems.append(f"perspective is not the scene's '{scene['perspective']}'")
    anchor = scene["anchors"].get(side["anchor"])
    if anchor is None: problems.append(f"unknown anchor '{side['anchor']}'")
    elif "w" in anchor and (anchor["w"], anchor["h"]) != (w, h): problems.append(f"canvas {w}x{h} is not the anchor's {anchor['w']}x{anchor['h']}")
    if side["fallbackAnimation"] not in animations: problems.append("fallbackAnimation is not a tag or sidecar animation")
    for anim, a in animations.items():
        if not a.get("frames") or a.get("fps", 0) <= 0: problems.append(f"'{anim}' needs frames and one positive fps (uneven tag durations? set fps in the sidecar)")
        problems += [f"'{anim}' uses frame {i} of {len(frames)}" for i in a.get("frames", []) if not 0 <= i < len(frames)]
        problems += [f"'{anim}' safe exit {i} is not one of its frames" for i in a.get("safeExits", []) if i not in a.get("frames", [])]
    assert not problems, f"{name}: " + "; ".join(problems)

    with open(manifest_path, "w") as f:
        json.dump(dict(id=name.lower(), type=side["type"], packVersion=1, perspective=side["perspective"], anchor=side["anchor"],
                       sheet="sheet.png", frame=dict(w=w, h=h), animations=animations, fallbackAnimation=side["fallbackAnimation"],
                       provenance=side.get("provenance", ""), source=rel_source), f, indent=2)
    print(f"{folder}: {len(frames)} frames of {w}x{h}, animations: {', '.join(animations)}")

if __name__ == "__main__":
    export(os.path.abspath(sys.argv[1]), *[os.path.abspath(p) for p in sys.argv[2:3]])
