# UI Asset Library

This folder stores generated UI mockups, sprite sheets, and sliced Godot-ready UI elements for 《废土生存法则》.

Source prompt pack:

```text
res://Doc/21_UI资源Sheet生成清单与提示词包_废土生存法则.md
```

Recommended structure:

```text
assets/ui/_style/
assets/ui/_mockups/
assets/ui/hud/sheets/
assets/ui/outlines/sheets/
assets/ui/inventory/sheets/
assets/ui/extraction/sheets/
assets/ui/base_nav/sheets/
assets/ui/warehouse/sheets/
assets/ui/research/sheets/
assets/ui/crafting/sheets/
assets/ui/prep/sheets/
assets/ui/icons/sheets/
assets/ui/icons/sliced/
```

Production rule:

```text
Mockups define layout and visual hierarchy.
Sprite sheets are transparent, grid-based, one element per cell, and ready for slicing.
Sliced UI elements should follow ui_[system]_[element]_[state].png.
Single icon slices should follow ui_icon_[element]_[state]_01.png.
Per-sheet slice manifests should follow ui_[sheet_name]_slices.tab.
```

First production batch:

```text
UI-00 ui_style_board_01.png
UI-01 ui_hud_mockup_01.png
UI-02 ui_hud_sheet_01.png
UI-04 ui_inventory_container_storage_mockup_01.png
UI-05 ui_inventory_container_storage_sheet_01.png
UI-08 ui_base_shell_mockup_01.png
```

Generated batch manifest:

```text
assets/ui/ui_asset_manifest.tab
assets/ui/ui_slice_manifest.tab
```

Preview contact sheet:

```text
assets/ui/_mockups/ui_asset_batch_preview_01.png
```

Sliced icon batch:

```text
assets/ui/icons/ui_system_icons_sheet_01_slices.tab
assets/ui/icons/ui_system_icons_sheet_01_slices_preview.png
assets/ui/icons/sliced/
```

Sliced production batch:

```text
assets/ui/hud/sliced/
assets/ui/outlines/sliced/
assets/ui/inventory/sliced/
assets/ui/extraction/sliced/
assets/ui/base_nav/sliced/
assets/ui/warehouse/sliced/
assets/ui/research/sliced/
assets/ui/crafting/sliced/
assets/ui/prep/sliced/
assets/ui/icons/sliced/
assets/ui/ui_slice_batch_preview_01.png
```
