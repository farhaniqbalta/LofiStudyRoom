# Art set E — PixelLab prompts and jobs

Usage is under PixelLab's Terms of Service. Reference: the user's concept image "Seaside Hut Through Three Lights" (local only, mood and composition).

Unused outputs were deleted on 2026-11-26 to keep the folder small. Their rows stay so the job ids can be found again; files no longer in `raw/` are marked *(removed)*.

## Test rooms — 2026-11-26 (3 generations)

All `create_image_pixen`, 480×352, `detail: highly detailed`, `view: high top-down`. Every prompt asks for a flat magenta #FF00FF opening, an empty seat facing it, indigo/teal night with amber lantern light, "No people, no animals."

| File | Seed | Job | Composition (prompt, short) |
|---|---|---|---|
| `raw/room-1.png` *(removed)* | 11 | `1832b9e2-5015-492d-93b9-5e4bd54f4c2b` | Centered: bookshelf left; open arch centre back with rope-wrapped posts, tied-back curtains, bougainvillea; pot, chest and floor lantern right; thatched roof, hanging lantern; low round table with books, mug, fruit bowl; empty round floor cushion in front of the table facing the opening |
| `raw/room-2.png` *(removed)* | 22 | `aa11eaec-1743-4f51-a13f-65ba4584bf8f` | Window seat: shelves with books, small wooden clock, hanging plants left; wide open window across the back wall, curtains, bougainvillea, shell wind chime; long low window-seat bench with an empty cushion facing the opening; chest with a small retro radio, pot and lantern right |
| `raw/room-3.png` *(removed)* | 33 | `55873814-c590-4e6a-987a-46ecfc1019b9` | Corner nook: low bed with blanket and pillows left, bookshelf and lantern; open window right of the back wall, curtains, bougainvillea; writing desk under it with notebook, mug, desk lantern; empty low stool facing the window |

## Converting the user's image — 2026-11-26 (2 generations)

Source: the night panel of the user's concept image (local only: `docs/reference/seaside-hut-three-lights.png`, git-ignored; x 1046–1671, y 471–939, 626×469), uploaded; the sunset panel is x 1046–1671, y 1–466. Tool `image_to_pixelart`, output 320×240, seed 7.

| File | Settings | Job | Result |
|---|---|---|---|
| `raw/px-night-faithful.png` | `faithful: true`, `init_image_strength: 200` | `38a14bfc-4504-448e-96ef-f3bec3b382f2` | 57 colours; keeps the source's look and blue moonlight, clean edges |
| `raw/px-night-redraw.png` *(removed)* | default (redraw) | `2a1997e0-aa98-4769-b47c-95604d84d06b` | 70 colours; chunkier classic pixel art, warmer, moonlight on the deck lost |
| `raw/px-night-faithful100.png` *(removed)* | `faithful: true`, `init_image_strength: 100` | `7b280a51-eeb8-479b-b732-7ac5c89d645e` | user asked to try lower faithfulness |
| `raw/px-sunset-faithful.png` | sunset panel (uploaded crop), `faithful: true`, strength 200 | `ed01a3c7-676c-4889-b561-348d8c32ec78` | 63 colours; used for `room-day.png` |
| `raw/px-sunset-faithful30.png` *(removed)* | sunset panel, `faithful: true`, `init_image_strength: 30` | `5434e090-e36f-4418-99e6-0b24e0206298` | user asked for less faithfulness |
| `raw/px-sunset-faithful10.png` *(removed)* | sunset panel, `faithful: true`, `init_image_strength: 10` | `1db9adb0-afa8-4b5d-8867-adada969651f` | user asked to try 10 |

## Boy — 2026-11-26 (1 generation)

| File | Tool | Job | Prompt (short) |
|---|---|---|---|
| `raw/boy-raw.png` 56×56 | `create_image_pixen`, `no_background`, `view: low top-down`, `direction: north`, selective outline, seed 5 | `9cad932f-d07f-471f-b666-ff0d68e8c1a2` | teenage boy seen from behind, sitting cross-legged, hands resting on a low table (not drawn), messy dark brown hair, headphones, cream linen shirt, navy shorts; "only the boy: no table, no cushion, no floor, no furniture" |

PixelLab drew a desk under his arms anyway. `raw/boy-shirt.png` is `boy-raw.png` with the desk planks and legs erased by hand (rows 28–48, outside the body), so the sprite holds no furniture.

## Boy, shirtless variant — 2026-11-26 (1 generation)

| File | Tool | Job | Prompt |
|---|---|---|---|
| `raw/boy-shirtless.png` 56×56 | `edit_image_pixen` on `raw/boy-shirt.png`, seed 5 | `02c2e312-407e-4748-8027-de3e7a53dcec` | The same boy, same pose seen from behind, same hair, headphones and navy shorts, but shirtless: bare back and shoulders with tanned skin and simple back shading. Keep the pose, size, outline and pixel style exactly the same. No table, no furniture. |

Silhouette differs from the shirt version by 60 px (the shirt's sleeves and hem), so both share one anchor. No furniture drawn this time.

## Boy poses (shirt) — 2026-11-26 (3 generations)

`edit_image_pixen` on `raw/boy-shirt.png`, each: "The same boy seen from behind, same hair, headphones, cream shirt and navy shorts, still sitting cross-legged in the same place. Now <pose>. Keep him facing away from the viewer, same size, outline and pixel style. No table, no furniture."

| File | Pose | Seed | Job | Result |
|---|---|---|---|---|
| `raw/boy-shirt-drink.png` | right arm raised, elbow bent, lifting a small mug to his mouth; left hand stays forward | 7 | `e7d841df-0afc-4472-bc96-45acd173d036` | good; left hand moved to his lap |
| `raw/boy-shirt-stretch.png` | both arms straight up above his head, hands together; "do not turn him toward the camera" | 11 | `f7aa29fa-9ab4-4c76-b266-aa07d33e5d7b` | stays from behind; body drawn narrower than the base |
| `raw/boy-shirt-rest.png` | arms folded forward, head lowered onto them, napping | 9 | `d1e1a6e8-274a-4d0f-a2d6-5a38eb42d3a5` | head tilts to the side rather than down; reads as dozing |

PixelLab drew the shirt lighter in all three. The kept files are recoloured to the base sprite: shirt pixels (light, low saturation) are matched to the base shirt's colours by lightness rank, every other pixel snaps to the nearest base colour. The unrecoloured outputs are not kept (download by job id).

## Boy poses (shirtless) — 2026-11-27 (3 generations)

`edit_image_pixen` on `raw/boy-shirtless.png`, the same pose prompts as the shirt boy with "shirtless ... bare back" (the stretch also says "at the same size").

| File | Pose | Seed | Job | Result |
|---|---|---|---|---|
| `raw/boy-shirtless-drink.png` | lifting a mug, right arm | 7 | `161b8b39-b30b-4508-8a34-0a78c23f3570` | good |
| `raw/boy-shirtless-stretch.png` | both arms up | 11 | `e7b6a7c5-bafb-4201-87f7-b90b4d79654e` | drawn about 1.2× too small again (legs 33 px against 39); scaled up to `raw/boy-shirtless-stretch-big.png` |
| `raw/boy-shirtless-rest.png` | head on folded arms | 9 | `a912653b-cbef-4694-bb68-9a832eda1e80` | head tilts to the side, like the shirt one |

All three are snapped to `boy-shirtless.png`'s palette (nearest colour).

## Cat — 2026-11-27 (1 generation)

| File | Tool | Job | Prompt (short) |
|---|---|---|---|
| `raw/cat-sit.png` 32×32 | `create_image_pixen`, `no_background`, `view: low top-down`, `direction: north`, selective outline, seed 5 | `b5facac0-49e8-4c39-b0b3-a251f814a685` | calico cat seen from behind, sitting upright, facing away looking at the sea, ears up, tail curled around its feet; white with orange and black patches; "only the cat: no cushion, no floor, no furniture" |

A pose unlike the other sets' cats (curled up asleep). The tail-lift, tail-sway and ear-twitch frames are made by `export.py`.
