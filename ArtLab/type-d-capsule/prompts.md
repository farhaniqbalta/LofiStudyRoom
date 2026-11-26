# Art set D — PixelLab prompts and jobs

Usage is under PixelLab's Terms of Service.

## Room 1, violet board room — `raw/room-1.png` (480×352)

- Tool: `create_image_pixen`, `view: side`, `detail: highly detailed`. Cost 1 generation.
- Job: `49949c84-08e5-4adc-b820-7eac2556b651` (2026-11-17)
- Prompt: Cozy cyberpunk bedroom at night, side view, pixel art, violet and magenta palette with a warm amber desk lamp. Wide window on the left whose glass is filled with one flat solid magenta #FF00FF color, nothing drawn in the glass. Wooden desk in the middle: computer monitor showing blue code, keyboard, mug, a small empty space on the desk left of the keyboard, a small digital clock with a blank dark screen left of the monitor, desk lamp. An empty dark gaming chair at the desk, turned to face left, nobody sitting in it, full chair visible down to the floor. Shelves above with books, a glowing lantern, small robot toy, hanging plants and pink string lights along the ceiling. Neon poster on the right wall, corner of a bed with purple blanket on the right. Visible floor strip at the bottom. No people, no animals.
- Check: glass is two magentas, (255,1,190) and (253,9,184), with blended edges, so it keys out with a threshold. Blinds cover the top of the glass. The chair faces right, toward the desk, so the character faces right (east), which mirrors the board.

## Room 3 variants, 2026-11-20 (3 generations)

Room 3's prompt with two changes: the chair is "an empty office chair seen exactly from the side in profile at the right end of the desk with its seat facing left toward the desk, drawn whole down to the floor", and the glass is "bare glass filled with one flat solid cyan color, no moon, no reflections, no glare, no curtains over the glass, nothing drawn in the glass". Same size and settings.

| File | Seed | Job |
|---|---|---|
| `raw/room-3a.png` | 11 | `50537b9f-f1dc-4160-a134-397bc933d340` |
| `raw/room-3b.png` | 22 | `a2a9b761-3843-4386-8259-c9ab10751b77` |
| `raw/room-3c.png` | 33 | `ea860569-e63d-487e-b238-5349f920a829` |

## Character, city, lamp off — 2026-11-21 (3 generations)

| File | Tool | Job | Prompt (short) |
|---|---|---|---|
| `raw/boy-rest.png` 128×176 | `create_image_pixen`, `no_background`, `view: side`, `direction: west` | `c40797cc-7e08-4f9d-8d08-a80de8054882` | teenage boy seated on an office chair seen from the side, facing left, full body, forearms raised typing, headphones, dark messy hair, navy hoodie with grey sleeve stripe, sneakers; "only the boy, no chair, no desk, no keyboard"; indigo/teal/amber |
| `raw/city-night.png` 232×224 | `create_image_pixen`, `view: side` | `3e194c73-a2e5-447d-884f-1b2ae4d2a128` | full-bleed night skyline from a high-rise, no frame or interior; cyberpunk towers, amber and teal windows, pink and cyan neon, elevated train; indigo/teal/amber |
| `raw/lamp-off-crop.png` 128×128 | `edit_image_pixen` on the room crop x 236–364, y 120–248 (top-left) | `65b3e775-34f4-429d-94d5-f31c6c97d965` | desk lamp off, no glow on wall or desk, same dim night tone, keep everything else |

## Boy from the user's image, and pose tests — 2026-11-24 (3 generations)

- `raw/boy-source-user.png` (1447×1087): supplied by the user ("Side-Profile Pixel Art Study Room"), a re-render of room 3a with a seated boy in side profile on a side-on chair. Source tool not stated; the user approved using it. It is not on a pixel grid (~190,000 colours), so it is scaled to 480×362 (best match to room 3a at offset 0, −5) and snapped to room 3a's palette. Only the boy and his chair are taken; the room stays our own 3a.
- `raw/boy-study-crop.png` (160×200): that scaled image, x 200–360, y 150–350 in room coordinates (top-left). Base for the pose edits.
- Pose edits: `edit_image_pixen` on `boy-study-crop.png`, seed 7, each "The same boy, same side profile, same chair, same clothes and headphones, now <pose>. Keep the camera, scale, chair, desk, lamp and background exactly the same."

| File | Pose | Job | Legs+chair drift (noise ≈ 20) | Verdict |
|---|---|---|---|---|
| `raw/boy-drink-crop.png` | lifts a coffee mug to his mouth | `3a578091-a711-4eef-bfa1-c45fc50b3b08` | 17 | consistent |
| `raw/boy-stretch-crop.png` | both arms straight up, eyes closed | `1ca07d59-9356-4be6-beb4-b82c72c3eae3` | 72 | **not consistent**: turned to face the camera; retry later |
| `raw/boy-rest-crop.png` | arms folded on the desk, head down | `53fc1b98-e7c3-40d0-af09-e78b7e7b9d16` | 24 | consistent |

## Stretch retry and cat — 2026-11-24 (4 generations)

| File | Tool | Job | Result |
|---|---|---|---|
| `raw/boy-stretch2-crop.png` | `edit_image_pixen` on `boy-study-crop.png`, seed 11: "Keep the exact side profile facing left ... only his arms change: he stretches both arms straight up above his head ... Do not turn him toward the camera." | `ccc75fe0-cf56-4fda-8a20-9066bc3c7cde` | **Rejected**: turned to face the camera again, new shoes and chair (drift 47) |
| `raw/cat-sleep.png` 32×32 | `create_image_pixen`, `no_background`, `view: side`, `direction: west`, black outline: orange tabby curled asleep, amber key light, teal rim | `0e9c5471-99c6-4756-bdd3-812b35e0e67d` | used |
| `raw/cat-awake.png` 32×32 | `edit_image_pixen` on the sleeping cat, seed 5: same pose, eyes open, head lifted | `c9ffdf94-5738-4441-9fdb-f6b7f074674a` | used as the tap reaction (face turns a little toward the viewer) |

## Lean-back routine and sharpening — 2026-11-24 (2.1 generations)

| File | Tool | Job | Result |
|---|---|---|---|
| `raw/boy-lean-crop.png` | `edit_image_pixen` on `boy-study-crop.png`, seed 13: "Keep the exact side profile facing left ... he leans back against the chair back, head tilted back looking up at the ceiling, eyes closed, both hands resting on his lap. Do not turn him toward the camera." | `25c2abd0-fe2f-439b-84ae-48f70142d748` | used (legs+chair drift 12) |
| `raw/boy-lean-cut.png` | `remove_background`, complex | `80d48a35-6469-441f-ab7e-0bd49c277c24` | used |
| `raw/boy-sharp-0..3.png` | `correct_pixelart`, strength 0.25, on the four boy frames | `bd24f30d-8c05-4d24-9984-3fa77350796c` | not used: barely changed, added ~3,000 near-duplicate colours |
| `raw/boy-study-crop-sharp.png` | none (free): the user's full-size image shrunk by majority colour per block, snapped to room 3a's palette | — | used for the study frame and the chair |

## Poses regenerated from the sharp crop — 2026-11-24 (6 generations)

Same prompts as before, plus "Keep the crisp pixel art with dark outlines", on `raw/boy-study-crop-sharp.png`. The soft first versions stay in `raw/`.

| Pose | Edit job | Drift (noise ≈ 20) | Cut-out job | Files |
|---|---|---|---|---|
| drink | `357a017f-7dd3-4373-b6c3-4dc14f7497ee` | 15.5 | `8b283029-b460-42b1-8c5c-37cac51eb1e0` | `boy-drink-crop-sharp.png`, `boy-drink-cut-sharp.png` |
| rest | `8a3a2039-c051-41c9-b47c-d34d82cc6838` | 25.2 | `50134808-af72-4335-b88f-676307e3d02c` | `boy-rest-crop-sharp.png`, `boy-rest-cut-sharp.png` |
| lean | `580cefd9-098d-402b-9600-9d491f7e0034` | 7.6 | `19d4044c-828d-4fff-b6c5-f99a309e1fbb` | `boy-lean-crop-sharp.png`, `boy-lean-cut-sharp.png` |

## Day city — 2026-11-24 (1 generation)

- `raw/city-day.png` 232×224: `edit_image_pixen` on the night city (job `3e194c73-…`), seed 3: "Same city skyline, same buildings, same framing and size, but in late afternoon daylight: soft bright sky with pale clouds, warm golden sunlight on the building faces, window lights off, neon signs dim." Job `140d68af-e91f-4b7a-8c18-394acff0ac97`. Every building stayed in place.

## Bigger cat — 2026-11-24 (1 generation)

- `raw/cat2-sleep.png` 48×48: `create_image_pixen`, `no_background`, `view: side`, `direction: west`, black outline: "orange tabby cat curled up asleep ... muted warm orange fur, not too saturated, soft cream chest, chunky pixel clusters with a dark single-colour outline ...". Job `0102d300-c285-4afb-95b3-0e1bcc2c228b`. It came with a teal cushion rim behind its back.
- `raw/cat2-awake.png` 48×48: `edit_image_pixen` on the sleeping cat, seed 5: "same curled pose ... on the same teal cushion, but awake: eyes open, head lifted a little, ears up, looking left". Job `4f8058b1-9229-4235-a027-4a465ee27abe` (2026-11-26). Shape identical (3 outline px differ).
