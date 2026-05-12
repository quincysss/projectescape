extends SceneTree

func _initialize() -> void:
	var ok := await _verify_currency_wallet_and_base_display()
	print("Currency wallet and base display verified." if ok else "Currency wallet and base display failed.")
	quit(0 if ok else 1)

func _verify_currency_wallet_and_base_display() -> bool:
	var game_state = get_root().get_node_or_null("GameState")
	if game_state == null:
		printerr("Expected GameState autoload.")
		return false
	game_state.clear_currencies()
	var result: Dictionary = game_state.add_currency("mine_coin", 37, "test_grant")
	if not bool(result.get("ok", false)):
		printerr("Expected adding mine_coin to succeed.")
		return false
	if game_state.get_currency_amount("mine_coin") != 37:
		printerr("Expected mine_coin amount to be stored by currency_id.")
		return false
	result = game_state.spend_currency("mine_coin", 12, "test_spend")
	if not bool(result.get("ok", false)) or game_state.get_currency_amount("mine_coin") != 25:
		printerr("Expected spending mine_coin to reduce stored currency.")
		return false
	result = game_state.spend_currency("mine_coin", 99, "test_overspend")
	if bool(result.get("ok", false)) or game_state.get_currency_amount("mine_coin") != 25:
		printerr("Expected failed spend to leave currency unchanged.")
		return false
	result = game_state.add_currency("mine_coin", 12, "restore_display_amount")
	if not bool(result.get("ok", false)) or game_state.get_currency_amount("mine_coin") != 37:
		printerr("Expected adding mine_coin to restore display amount.")
		return false

	var base_scene := load("res://scenes/base/BaseScene.tscn")
	if base_scene == null:
		printerr("Expected BaseScene to load.")
		return false
	var base_root = base_scene.instantiate()
	get_root().add_child(base_root)
	await process_frame
	var currency_label := base_root.get_node_or_null("BaseUIRoot/CurrencyLabel") as Label
	if currency_label == null:
		printerr("Expected CurrencyLabel in BaseScene.")
		base_root.queue_free()
		return false
	if currency_label.anchor_left != 1.0 or currency_label.anchor_right != 1.0:
		printerr("Expected CurrencyLabel anchored to the out-of-run top right.")
		base_root.queue_free()
		return false
	if currency_label.horizontal_alignment != HORIZONTAL_ALIGNMENT_RIGHT:
		printerr("Expected CurrencyLabel text to align right.")
		base_root.queue_free()
		return false
	if not currency_label.text.contains("37"):
		printerr("Expected CurrencyLabel to show current mine_coin amount, got %s." % currency_label.text)
		base_root.queue_free()
		return false
	base_root.queue_free()
	await process_frame

	var run_scene := load("res://scenes/run/RunScene.tscn")
	if run_scene == null:
		printerr("Expected RunScene to load.")
		return false
	var run_root = run_scene.instantiate()
	get_root().add_child(run_root)
	await process_frame
	if run_root.find_child("CurrencyLabel", true, false) != null:
		printerr("Expected currency display to be absent from RunScene.")
		run_root.queue_free()
		return false
	run_root.queue_free()
	await process_frame
	return true
