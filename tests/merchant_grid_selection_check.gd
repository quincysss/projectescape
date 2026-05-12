extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const SELECTED_BORDER := Color("#D1B850")

func _initialize() -> void:
	var ok := await _verify_merchant_grid_selection()
	print("Merchant grid selection verified." if ok else "Merchant grid selection failed.")
	quit(0 if ok else 1)

func _verify_merchant_grid_selection() -> bool:
	var game_state = root.get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	await process_frame
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Expected registry to load.")
		return false

	game_state.clear_warehouse()
	game_state.clear_currencies()
	game_state.add_currency("mine_coin", 100, "merchant_grid_selection")
	game_state.add_to_warehouse([
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("field_bandage"),
		registry.make_item_stack("field_bandage"),
	])
	game_state.merchant_shop_offers.clear()
	game_state.merchant_shop_offers.append({
		"shop_offer_id": "test_offer_scrap",
		"shop_id": "base_merchant",
		"shop_level": 1,
		"min_shop_level": 1,
		"item_id": "scrap_metal",
		"display_name": "废金属",
		"item_type": "material",
		"quality": "C",
		"count": 4,
		"buy_currency_id": "mine_coin",
		"buy_price": 1,
	})

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	root.add_child(base_root)
	await process_frame

	var merchant_tab := base_root.get_node_or_null("BaseUIRoot/MerchantTabButton") as Button
	if merchant_tab == null:
		printerr("Expected merchant tab.")
		base_root.queue_free()
		return false
	merchant_tab.emit_signal("pressed")
	await process_frame

	var ok := true
	ok = await _select_and_expect_one(base_root.merchant_sell_grid_root, 1, "sell") and ok
	ok = await _select_and_expect_one(base_root.merchant_shop_grid_root, 2, "buy") and ok

	base_root.queue_free()
	await process_frame
	return ok

func _select_and_expect_one(grid_root: Control, button_index: int, label: String) -> bool:
	var buttons := _grid_buttons(grid_root)
	if buttons.size() <= button_index:
		printerr("Expected enough %s grid buttons." % label)
		return false
	buttons[button_index].emit_signal("button_up")
	await process_frame
	buttons = _grid_buttons(grid_root)
	var selected_count := 0
	for button in buttons:
		if _is_selected_button(button):
			selected_count += 1
	if selected_count != 1:
		printerr("Expected exactly one selected %s grid slot, got %d." % [label, selected_count])
		return false
	if not _is_selected_button(buttons[button_index]):
		printerr("Expected clicked %s grid slot to be selected." % label)
		return false
	return true

func _grid_buttons(grid_root: Control) -> Array[Button]:
	var buttons: Array[Button] = []
	if grid_root == null:
		return buttons
	for child in grid_root.get_children():
		if child is Button:
			buttons.append(child)
	return buttons

func _is_selected_button(button: Button) -> bool:
	var style := button.get_theme_stylebox("normal") as StyleBoxFlat
	if style == null:
		return false
	return style.border_color.is_equal_approx(SELECTED_BORDER) and style.border_width_left >= 3
