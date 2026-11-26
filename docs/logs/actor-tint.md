# Actor tint by room state

**Status:** Done, 2026-11-26. Branch `feature/actor-tint`.

## Why

From the set D cohesion review: characters and pets are drawn under one light (night, lamp on), so with the lamp off they kept glowing and in the day they stayed at night colours while the room changed.

## What

- Scene manifest: optional `actorTints`, keyed like `rooms` (`<day|night>-<on|off>`), each `{ "color": "#RRGGBB", "amount": 0...1 }`. A missing key means no tint.
- `LoFiSKScene.apply` sets the character's and pet's `color` and `colorBlendFactor` (the colour is multiplied in). No nodes added, no per-frame work; a pack swap keeps the tint.
- `ScenePack.problems()` reports unknown keys, malformed colours and amounts outside 0–1.
- Values, written by each set's build script: sets A and D get a cool dark tint for night with the lamp off (`#5A5C8C`, 0.45) and a light warm one for day (D `#FFE6C0` 0.25, A `#FFE6C8` 0.2). Set B has none.

## Results

- New tests: `testActorTintFollowsRoomState` (on the fixture scene), `testActorTintProblems`. `Executed 136 tests, with 0 failures` on the iPad.
- Screenshots: `build/shots/tint-D-night-off.png`, `tint-D-day-on.png`, `tint-A-night-off.png`.
