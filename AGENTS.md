# ProjectEscape Agent Guidance

This is a Godot project. Optimize agent work for source-level changes and avoid loading generated or binary-heavy content by default.

Preferred context for most tasks:
- `scripts/`
- `scenes/`
- `tests/`
- `setting/`
- `data/`
- `Doc/`
- `.codex/`
- `project.godot`

Avoid default recursive reads of:
- `.git/`
- `.godot/`
- `build/`
- `.vs/`
- `reports/`
- `assets/` binary media
- `addons/ffmpeg/`
- temporary files and export packages

Only inspect ignored/binary areas when the user explicitly asks about assets, exports, Godot import state, or packaged builds.
