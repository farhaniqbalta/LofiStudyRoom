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
