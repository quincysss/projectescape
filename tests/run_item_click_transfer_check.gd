extends SceneTree

func _initialize() -> void:
	var ok := await _verify_run_item_click_transfer()
	print("Run item click transfer verified." if ok else "Run item click transfer failed.")
	quit(0 if ok else 1)

func _verify_run_item_click_transfer() -> bool:
	var scene := load("res://scenes/run/RunScene.tscn")
	if scene == null:
		printerr("Failed to load RunScene.")
		return false
	var root = scene.instantiate()
	get_root().add_child(root)
	await process_frame
	await process_frame

	root.run_director.inventory_component.setup(64, 100.0)
	var container = _find_interactable(root, "container")
	if container == null:
		printerr("Expected a container.")
		return false
	root._open_container(container)
	var initial_loot_count: int = root.opened_loot.size()
	if initial_loot_count <= 0:
		printerr("Expected opened container loot.")
		return false
	root._on_loot_item_meta_clicked("loot:0")
	if root.run_director.inventory_component.items.size() != 1:
		printerr("Expected clicked loot item to move into backpack.")
		return false
	if initial_loot_count > 1 and root.opened_loot.size() != initial_loot_count - 1:
		printerr("Expected only one clicked loot item to be removed from loot.")
		return false

	root._on_inventory_item_meta_clicked("inventory:0")
	if root.run_director.inventory_component.items.size() != 0 or root.run_director.home_storage_component.items.size() != 1:
		printerr("Expected clicked backpack item to move into home storage.")
		return false

	root._on_home_storage_item_meta_clicked("home:0")
	if root.run_director.inventory_component.items.size() != 1 or root.run_director.home_storage_component.items.size() != 0:
		printerr("Expected clicked home item to move back into backpack.")
		return false
	return true

func _find_interactable(root, interact_type: String):
	for interactable in root.interactables:
		if is_instance_valid(interactable) and interactable.interact_type == interact_type:
			return interactable
	return null
