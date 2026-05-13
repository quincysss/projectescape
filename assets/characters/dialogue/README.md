# Dialogue Character Portraits

This folder stores standalone character bust portraits for story dialogue.

## Runtime Paths

```text
assets/characters/dialogue/player/player_dialogue_bust_01.png
assets/characters/dialogue/operator_404/operator_404_dialogue_bust_01.png
assets/characters/dialogue/common/dialogue_portrait_placeholder.png
```

## Naming Rules

- Use lowercase English, underscores, and a numeric version suffix.
- Character folder names must match `speaker_id` from `setting/dialogue_speakers.tab`.
- Final runtime portraits use `<speaker_id>_dialogue_bust_01.png`.
- GPT source outputs and chroma-key intermediates live under `_source/` and must not be referenced by runtime data.

## Art Rules

- Size: `1024x1024` or `1024x1536`.
- Content: half-body or upper half-body bust, waist-up preferred.
- Background: transparent PNG for final runtime files.
- Composition: no cropped head or shoulders, clean padding.
- View: front or three-quarter front.
- Style: dark gray hand-drawn manga line art, gritty wasteland texture, restrained blue-purple or warm-yellow accents.
- Avoid: bright cyberpunk neon, clean new military uniform, exaggerated anime expressions, modern school/city clothing, top-down gameplay sprites.

## GPT Image 2 Source

Generation prompts are stored in:

```text
assets/characters/dialogue/_source/dialogue_portrait_prompts_gpt_image_2_v01.jsonl
```

`gpt-image-2` does not support native transparent output, so source generation uses a flat `#00ff00` chroma-key background. Remove the key locally and save only the cleaned alpha PNG to the runtime paths above.

Recommended generation command from the Godot project root:

```powershell
python "C:\Users\KSG\.codex\skills\.system\imagegen\scripts\image_gen.py" generate-batch `
  --input "assets\characters\dialogue\_source\dialogue_portrait_prompts_gpt_image_2_v01.jsonl" `
  --out-dir "assets\characters\dialogue\_source" `
  --model gpt-image-2 `
  --size 1024x1536 `
  --quality high `
  --output-format png `
  --no-augment
```

Post-process each generated chroma source into the runtime PNG:

```powershell
python "C:\Users\KSG\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py" `
  --input "assets\characters\dialogue\_source\player_dialogue_bust_01_chroma.png" `
  --out "assets\characters\dialogue\player\player_dialogue_bust_01.png" `
  --auto-key border `
  --soft-matte `
  --transparent-threshold 12 `
  --opaque-threshold 220 `
  --despill

python "C:\Users\KSG\.codex\skills\.system\imagegen\scripts\remove_chroma_key.py" `
  --input "assets\characters\dialogue\_source\operator_404_dialogue_bust_01_chroma.png" `
  --out "assets\characters\dialogue\operator_404\operator_404_dialogue_bust_01.png" `
  --auto-key border `
  --soft-matte `
  --transparent-threshold 12 `
  --opaque-threshold 220 `
  --despill
```

Current status is tracked in `_source/dialogue_portrait_generation_manifest_v01.json`. The player and operator runtime portraits are final generated art; the common fallback remains a placeholder silhouette.
