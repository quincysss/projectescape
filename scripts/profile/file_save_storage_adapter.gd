class_name FileSaveStorageAdapter
extends RefCounted

const PROFILE_PATH := "user://profile/profile.json"
const TEST_PROFILE_PATH := "user://profile/test_profile.json"
const PROFILE_DIR := "user://profile"

func save_profile(profile: Dictionary) -> Dictionary:
	var dir_result := _ensure_profile_dir()
	if not bool(dir_result.get("ok", false)):
		return dir_result
	var file := FileAccess.open(_profile_path(), FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"reason": "open_failed",
			"error": FileAccess.get_open_error(),
		}
	file.store_string(JSON.stringify(profile, "\t"))
	file.close()
	return {"ok": true, "path": _profile_path()}

func load_profile() -> Dictionary:
	if not has_profile():
		return {}
	var file := FileAccess.open(_profile_path(), FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	return parsed if parsed is Dictionary else {}

func has_profile() -> bool:
	return FileAccess.file_exists(_profile_path())

func delete_profile_debug_only() -> Dictionary:
	if not has_profile():
		return {"ok": true, "deleted": false}
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(_profile_path()))
	return {"ok": err == OK, "deleted": err == OK, "error": err}

func get_active_profile_path() -> String:
	return _profile_path()

func _ensure_profile_dir() -> Dictionary:
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE_DIR))
	return {"ok": err == OK or err == ERR_ALREADY_EXISTS, "reason": "mkdir_failed", "error": err}

func _profile_path() -> String:
	var override_path := OS.get_environment("PROJECT_ESCAPE_PROFILE_PATH").strip_edges()
	if not override_path.is_empty():
		return override_path
	return TEST_PROFILE_PATH if _is_running_test_script() else PROFILE_PATH

func _is_running_test_script() -> bool:
	for arg in OS.get_cmdline_args():
		var normalized := String(arg).replace("\\", "/")
		if normalized.begins_with("res://tests/") or normalized.contains("/tests/"):
			return true
	return false
