extends SceneTree

const FileSaveStorageAdapterScript := preload("res://scripts/profile/file_save_storage_adapter.gd")


func _initialize() -> void:
	var adapter = FileSaveStorageAdapterScript.new()
	var path := adapter.get_active_profile_path()
	if path != FileSaveStorageAdapterScript.TEST_PROFILE_PATH:
		printerr("Expected tests to use isolated profile path, got %s." % path)
		quit(1)
		return
	var save_result: Dictionary = adapter.save_profile({"username": "storage_test", "warehouse_items": []})
	if not bool(save_result.get("ok", false)):
		printerr("Expected isolated test profile save to pass: %s." % save_result)
		quit(1)
		return
	if not adapter.has_profile():
		printerr("Expected isolated test profile to exist after save.")
		quit(1)
		return
	adapter.delete_profile_debug_only()
	print("Profile storage isolation verified.")
	quit(0)
