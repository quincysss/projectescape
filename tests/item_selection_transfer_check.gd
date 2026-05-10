extends SceneTree

const InventoryComponentScript := preload("res://scripts/inventory/inventory_component.gd")
const HomeStorageComponentScript := preload("res://scripts/inventory/home_storage_component.gd")
const ItemTransferServiceScript := preload("res://scripts/inventory/item_transfer_service.gd")
const WarehouseManagerScript := preload("res://scripts/game/warehouse_manager.gd")

func _initialize() -> void:
	var ok := _verify_transfer_service() and _verify_warehouse_selection()
	print("Item selection transfer verified." if ok else "Item selection transfer failed.")
	quit(0 if ok else 1)

func _verify_transfer_service() -> bool:
	var service = ItemTransferServiceScript.new()
	var inventory = InventoryComponentScript.new()
	var storage = HomeStorageComponentScript.new()
	get_root().add_child(inventory)
	get_root().add_child(storage)
	inventory.setup(2, 10.0)
	storage.setup(4)

	var source: Array = [
		_item("scrap_metal", "废金属", 1.0),
		_item("cloth_dirty", "脏布条", 0.5),
	]
	var result: Dictionary = service.transfer_index_to_inventory(source, 1, inventory)
	if not result.accepted or source.size() != 1 or inventory.items.size() != 1:
		printerr("Expected selected source item to move into inventory.")
		return false
	if String(inventory.items[0].item_id) != "cloth_dirty":
		printerr("Expected clicked item, not first item, to move.")
		return false

	result = service.transfer_inventory_to_storage(inventory, 0, storage)
	if not result.accepted or inventory.items.size() != 0 or storage.items.size() != 1:
		printerr("Expected selected inventory item to move into home storage.")
		return false

	result = service.transfer_storage_to_inventory(storage, 0, inventory)
	if not result.accepted or inventory.items.size() != 1 or storage.items.size() != 0:
		printerr("Expected selected home storage item to move back into inventory.")
		return false

	inventory.setup(1, 10.0)
	if not inventory.add_item(_item("slot_a", "占格物", 1.0)):
		printerr("Expected setup item add to pass.")
		return false
	result = service.transfer_index_to_inventory(source, 0, inventory)
	if result.accepted or source.size() != 1:
		printerr("Expected rejected selected transfer to leave source untouched.")
		return false
	return true

func _verify_warehouse_selection() -> bool:
	var warehouse = WarehouseManagerScript.new()
	var items: Array[Dictionary] = []
	warehouse.bind_items(items)
	warehouse.add_items([_item("scrap_metal", "废金属", 1.0).merged({"amount": 3}, true)])
	if items.size() != 3:
		printerr("Expected warehouse add to split amount into single items.")
		return false
	var selected: Dictionary = warehouse.select_item_at(2)
	if selected.is_empty() or int(selected.amount) != 1:
		printerr("Expected warehouse selection by index to return one item instance.")
		return false
	var removed: Dictionary = warehouse.remove_item_at(1)
	if removed.is_empty() or items.size() != 2:
		printerr("Expected warehouse removal by index.")
		return false
	return true

func _item(item_id: String, display_name: String, weight: float) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"amount": 1,
		"weight_per_unit": weight,
		"stack_limit": 1,
		"item_type": "material",
		"quality": "C",
	}
