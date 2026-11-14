# Lo-Fi Room — Pixel-Art Mockup Exploration Brief

**Status:** Visual exploration, NOT new feature scope.  
**Use with:** `LOCKED_MVP_SPEC.md`  
**Target display:** iPad landscape (create composition with approx. 4:3 safe crop; avoid designing only for 16:9).

## The shared scene identity

A cozy, atmospheric **2D pixel-art** cyberpunk study room. One person (boy or girl variant) sits at a desk working; a swappable cat sleeps near them; an **in-world pixel-digit clock** shows the true local `HH:mm`; a tiny computer/record player surface opens a subtle Spotify now-playing overlay when tapped. Main experience is passive, calm and low-power. Tiny visual loops: study posture, occasional mug sip, cat ear/tail, rain, neon flicker, reflected traffic. No game HUD, resources, upgrade buttons or quests.

## Visual explorations (same sprite integration contract)

### A. Rainy Neon Apartment — base direction

- Side-on desk positioned to right of a broad window, warm amber task light against violet/cyan cyber skyline.
- Shelves and a bed/cushion in the peripheral space, a pet sleeping near the desk.
- In-world clock on desk with reusable turquoise digit sprites; optional tiny now-playing overlay shown as a quiet contextual panel.
- Show the window with *flat independent background layers* suitable for rain and a train effect later.

### B. Rooftop Greenhouse Studio — warmer alternate aesthetic

- Exact same functional furniture anchors and primary room silhouette as A, but plants and a distant elevated rooftop skyline make it feel more botanical.
- Warm amber/teal palette, less pink saturation; clear or light rain visual toggle.
- Keep character, pet, clock and computer at precisely compatible positions to demonstrate reuse.

### C. Transit District / Night Train — alternate scenery

- Same core room geometry, but the wide window overlooks futuristic elevated rail, neon storefronts and distant towers.
- Blue/violet night with selective warm window rectangles; the train is an **optional separate animated layer**, not a required simulation.
- Avoid adding new gameplay objects; emphasis on how scenery changes the emotional tone.

## Artwork targets / rules

1. Use strict readable **pixel-art** clusters and deliberately limited palette; no soft anime painting disguised as pixelated art.
2. One coherent fixed camera angle, logical grid and stable scale; character variants should occupy the exact same chair anchor.
3. Keep desk, lamp, clock, pet cushion and computer visible within iPad's landscape-safe composition.
4. Make city/buildings, weather effects, character, cat, clock digits, lamp state and HUD *visually separable* into sprite packs.
5. No oversized persistent HUD. Only tiny now-playing when deliberately opened; no gameplay UI.
6. Make the room sufficiently static that only a few parts need animation. Design loopable sprite motion as a future production task, not evidence that concept art alone can be animated.
7. The two official MVP background views should share the same room; concept B can be explored as a **visual theme**, not automatically a second room layout feature.
8. Character variants: boy and girl. Pet variants: orange and black cat. Dog remains deferred, regardless of mockup experiments.

## Questions to evaluate during design review

- Which palette remains legible on an iPad at reduced brightness?
- Can boy/girl and orange/black cat silhouettes align to the same anchors and retain readable poses?
- Does the clock read clearly without becoming a dominant HUD?
- Which backdrop has enough negative space for occasional moving layers while remaining calm?
- Does the UI vanish elegantly when dismissed, leaving an aesthetically complete scene?
- Can the room be assembled from reasonably sized assets without a huge number of transparent full-screen sprites?
- Do rain and city effects remain believable at 15–30 FPS or deliberately low-animation-frequency loops?

## First deliverable after choosing a visual direction

Prepare a layered room layout guide, anchor map, logical pixel canvas proposal (validated on actual iPad), sprite asset inventory, animation frame counts/durations, and two variants of each official MVP customizable category. Do not derive an exhaustive animation sheet from a generated concept image without an artist/asset-production pass.
