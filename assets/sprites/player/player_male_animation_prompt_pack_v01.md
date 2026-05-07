# Player Male 4-Direction Animation Prompt Pack V01

This pack follows `Doc/17` and the existing player seed sprites in `assets/sprites/player`.

## Production Decision

- Character: `player_male`, lonely teenage wasteland survivor.
- Source reference: `assets/sprites/player/sheets/player_male_idle_4dir_sheet_01.png`.
- Frame size: 256x256.
- Strip layout: 8 frames in one horizontal row, 2048x256 total.
- Direction order for final Godot animations: down, up, left, right.
- Animation set:
  - `idle`: 8 frames, subtle breathing and weight shift loop.
  - `run`: 8 frames, urgent survival run, readable limbs, stable backpack.
  - `interact`: 8 frames, generic loot/search/repair interaction, holdable loop.
- Anchor: bottom-center, keep shoes/feet landing near the same baseline in every frame.
- Background workflow for gpt-image-2.0: generate on flat chroma green `#00ff00`, then remove chroma to alpha PNG locally. Do not use green inside the character.

## Character Lock

Use this exact character description in every prompt:

```text
Same male teenage survivor as the reference sprite: thin body, messy black hair covering part of the face, oversized dirty grey T-shirt, worn black shorts, heavy old sneakers, rugged dark backpack, tiny purple and electric-blue electronic modules on the shirt, shorts, and backpack. Dark hand-drawn manga line art, thick black outline, dirty grayscale clothing texture, lonely post-apocalyptic urban survivor mood. Keep the same proportions, same silhouette family, same backpack shape, same hair mass, same muted palette, and the same tiny purple/blue accent placement.
```

## Universal Negative Prompt

Append this to every request:

```text
Avoid: cute chibi proportions, glossy anime, photorealism, 3D render, clean sci-fi suit, military armor, weapons as the focus, gore, extra characters, scenery, floor shadows, cast shadows, labels, frame numbers, text, watermark, poster composition, camera perspective horizon, cropped body, changing costume, changing backpack, changing hair style, large bright color areas, green color on the character.
```

## Generation Template

Replace `[DIRECTION]` and `[ACTION_SPEC]` with the direction block below.

```text
Create one complete 2D game sprite animation strip for gpt-image-2.0.

Reference role: use the provided four-direction idle player sprite sheet as the identity, costume, palette, line density, and silhouette reference.

Subject lock:
Same male teenage survivor as the reference sprite: thin body, messy black hair covering part of the face, oversized dirty grey T-shirt, worn black shorts, heavy old sneakers, rugged dark backpack, tiny purple and electric-blue electronic modules on the shirt, shorts, and backpack. Dark hand-drawn manga line art, thick black outline, dirty grayscale clothing texture, lonely post-apocalyptic urban survivor mood. Keep the same proportions, same silhouette family, same backpack shape, same hair mass, same muted palette, and the same tiny purple/blue accent placement.

View:
2D top-down or slightly top-down game sprite, [DIRECTION] facing only. Do not rotate the camera between frames.

Animation:
[ACTION_SPEC]

Production layout:
Exactly 8 animation frames in one horizontal row.
Each frame occupies one clean 256x256 slot.
Total canvas should read as a 2048x256 horizontal sprite strip.
Keep one character centered in each slot.
Keep feet on a shared baseline and align the whole strip to bottom-center.
Preserve consistent body scale and head size across all frames.
Use crisp transparent-ready cutout edges with no scenery.

Background for removal:
Perfectly flat solid #00ff00 chroma-key background only.
The background must be one uniform color with no shadows, gradients, texture, floor plane, or lighting variation.
Do not use #00ff00 anywhere on the character.

Style:
Dark hand-drawn manga line art, rough dirty grayscale ink texture, thick black outline, readable silhouette at 128x128 and 256x256, tiny purple and electric-blue device lights only.

Avoid: cute chibi proportions, glossy anime, photorealism, 3D render, clean sci-fi suit, military armor, weapons as the focus, gore, extra characters, scenery, floor shadows, cast shadows, labels, frame numbers, text, watermark, poster composition, camera perspective horizon, cropped body, changing costume, changing backpack, changing hair style, large bright color areas, green color on the character.
```

## Idle Strips

### `player_male_idle_down_strip_01`

```text
[DIRECTION] = facing down, front of body visible, head tilted slightly downward, backpack straps visible at shoulders.
[ACTION_SPEC] = Idle breathing loop, 8 frames. Very subtle chest rise and fall, slight shoulder sag, tiny hair sway, tiny backpack strap movement, tiny weight shift between both feet. Frame 1 and frame 8 should connect smoothly. No walking, no arm swing, no dramatic pose.
```

### `player_male_idle_up_strip_01`

```text
[DIRECTION] = facing up, back of body visible, backpack fully visible, back of messy hair visible.
[ACTION_SPEC] = Idle breathing loop, 8 frames. Subtle backpack lift and settle with breathing, tiny shoulder movement, small hair movement, tiny weight shift between both feet. Frame 1 and frame 8 should connect smoothly. No walking, no turning, no dramatic pose.
```

### `player_male_idle_left_strip_01`

```text
[DIRECTION] = facing left, side profile, nose and hair silhouette facing left, backpack seen from side.
[ACTION_SPEC] = Idle breathing loop, 8 frames. Subtle chest motion, small shoulder dip, tiny hand and hair movement, tiny weight shift without stepping. Frame 1 and frame 8 should connect smoothly. No walking, no turning, no dramatic pose.
```

### `player_male_idle_right_strip_01`

```text
[DIRECTION] = facing right, side profile, nose and hair silhouette facing right, backpack seen from side.
[ACTION_SPEC] = Idle breathing loop, 8 frames. Subtle chest motion, small shoulder dip, tiny hand and hair movement, tiny weight shift without stepping. Frame 1 and frame 8 should connect smoothly. No walking, no turning, no dramatic pose.
```

## Run Strips

### `player_male_run_down_strip_01`

```text
[DIRECTION] = facing down, front of body visible while running toward the viewer in top-down sprite style.
[ACTION_SPEC] = Urgent survival run loop, 8 frames. Alternating left and right foot contacts, compact arm pump close to the body, slight forward lean, messy hair bouncing, backpack lagging and bouncing. Keep the run desperate but readable, not athletic superhero sprint. Frames 1 and 5 are opposite foot contact poses; frame 8 loops back to frame 1 smoothly.
```

### `player_male_run_up_strip_01`

```text
[DIRECTION] = facing up, back of body and backpack visible while running away from the viewer in top-down sprite style.
[ACTION_SPEC] = Urgent survival run loop, 8 frames. Alternating foot contacts, compact arm pump partly hidden by torso and backpack, backpack bouncing with straps, shoulders twisting slightly, hair bouncing. Frames 1 and 5 are opposite foot contact poses; frame 8 loops back to frame 1 smoothly.
```

### `player_male_run_left_strip_01`

```text
[DIRECTION] = facing left, side profile running left.
[ACTION_SPEC] = Urgent survival run loop, 8 frames. Clear side-view leg cycle with one contact pose, one passing pose, one extension pose, and opposite contact. Arms pump compactly, torso leans slightly forward, backpack bounces behind the shoulder, hair trails with motion. Frames 1 and 5 are opposite foot contact poses; frame 8 loops back to frame 1 smoothly.
```

### `player_male_run_right_strip_01`

```text
[DIRECTION] = facing right, side profile running right.
[ACTION_SPEC] = Urgent survival run loop, 8 frames. Clear side-view leg cycle with one contact pose, one passing pose, one extension pose, and opposite contact. Arms pump compactly, torso leans slightly forward, backpack bounces behind the shoulder, hair trails with motion. Frames 1 and 5 are opposite foot contact poses; frame 8 loops back to frame 1 smoothly.
```

## Interact Strips

Use this as a generic interaction for containers, outpost repairs, and extraction hold actions. The object should not be drawn; the pose must imply the player is using/searching something just outside the sprite slot.

### `player_male_interact_down_strip_01`

```text
[DIRECTION] = facing down, front of body visible, hands reaching slightly forward and downward toward an unseen object below the character.
[ACTION_SPEC] = Generic search/repair interaction loop, 8 frames. The survivor bends slightly, brings both hands forward, performs a cautious rummaging or tightening motion, then returns to a hold-ready pose. Small shoulder movement, head lowered, backpack shifts subtly. No visible container or tool, no new props. Frames 3 to 6 should be usable as a held interaction loop.
```

### `player_male_interact_up_strip_01`

```text
[DIRECTION] = facing up, back of body and backpack visible, hands reaching toward an unseen object above the character.
[ACTION_SPEC] = Generic search/repair interaction loop, 8 frames. The survivor leans forward from the back view, shoulders hunch, arms move in a cautious rummaging or repair motion, backpack lifts and settles slightly. No visible container or tool, no new props. Frames 3 to 6 should be usable as a held interaction loop.
```

### `player_male_interact_left_strip_01`

```text
[DIRECTION] = facing left, side profile, hands reaching toward an unseen object on the left.
[ACTION_SPEC] = Generic search/repair interaction loop, 8 frames. The survivor leans toward the left, bends at the waist, extends both hands, performs a small rummaging or tightening motion, then settles into a hold-ready pose. Backpack shifts slightly backward. No visible container or tool, no new props. Frames 3 to 6 should be usable as a held interaction loop.
```

### `player_male_interact_right_strip_01`

```text
[DIRECTION] = facing right, side profile, hands reaching toward an unseen object on the right.
[ACTION_SPEC] = Generic search/repair interaction loop, 8 frames. The survivor leans toward the right, bends at the waist, extends both hands, performs a small rummaging or tightening motion, then settles into a hold-ready pose. Backpack shifts slightly backward. No visible container or tool, no new props. Frames 3 to 6 should be usable as a held interaction loop.
```

## Post-Generation Cut Rules

1. Remove the chroma background to alpha PNG.
2. Cut every strip into 8 frames of 256x256.
3. Keep bottom-center anchor identical across all frames.
4. Lock or manually repaint frame 1 of each idle direction to closely match the existing shipped idle pose when possible.
5. Export individual frames using this pattern:

```text
assets/sprites/player/player_male_[animation]_[direction]_[frame].png
```

Example:

```text
assets/sprites/player/player_male_run_down_01.png
assets/sprites/player/player_male_run_down_02.png
...
assets/sprites/player/player_male_run_down_08.png
```

## Quality Gate

- All frames have alpha and transparent corners after chroma removal.
- No green fringe remains around hair, shoes, or backpack.
- Scale drift is less than 5 percent across each strip.
- Feet stay on a stable baseline.
- Direction never flips within a strip.
- Purple/blue electronic accents stay tiny and consistent.
- Backpack remains readable in up and side views.
- Idle reads as breathing, not walking.
- Run reads at 128x128.
- Interact works without drawing the target object.
