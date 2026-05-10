class_name OutpostStorageController
extends RefCounted

signal outpost_storage_changed(outpost_id: String, items: Array)

const StorageContainerScript := preload("res://scripts/inventory/storage_container.gd")

var storages: Dictionary = {}

func clear() -> void:
	storages.clear()

func ensure_storage(outpost_id: String, capacity_slots: int):
	if outpost_id.is_empty():
		return null
	if storages.has(outpost_id):
		return storages[outpost_id]
	var storage = StorageContainerScript.new()
	storage.setup("storage_%s" % outpost_id, outpost_id, capacity_slots, true)
	storage.storage_changed.connect(func(items): outpost_storage_changed.emit(outpost_id, items))
	storages[outpost_id] = storage
	outpost_storage_changed.emit(outpost_id, storage.get_items_snapshot())
	return storage

func get_storage(outpost_id: String):
	return storages.get(outpost_id, null)

func has_storage(outpost_id: String) -> bool:
	return storages.has(outpost_id)

func get_items_snapshot(outpost_id: String) -> Array:
	var storage = get_storage(outpost_id)
	if storage == null:
		return []
	return storage.get_items_snapshot()

func get_slots_snapshot(outpost_id: String) -> Array:
	var storage = get_storage(outpost_id)
	if storage == null:
		return []
	return storage.get_slots_snapshot()

func get_all_items_snapshot() -> Array:
	var all_items: Array[Dictionary] = []
	for outpost_id in storages.keys():
		var storage = get_storage(str(outpost_id))
		if storage == null:
			continue
		for item in storage.get_items_snapshot():
			if item is Dictionary:
				var entry: Dictionary = item.duplicate(true)
				entry["source"] = "outpost_storage"
				entry["source_outpost_id"] = str(outpost_id)
				all_items.append(entry)
	return all_items

func get_debug_snapshot() -> Dictionary:
	var snapshot := {}
	for outpost_id in storages.keys():
		snapshot[outpost_id] = get_slots_snapshot(str(outpost_id))
	return snapshot
