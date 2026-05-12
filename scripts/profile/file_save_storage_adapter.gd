class_name FileSaveStorageAdapter
extends RefCounted

const PROFILE_PATH := "user://profile/profile.json"
const PROFILE_DIR := "user://profile"

func save_profile(profile: Dictionary) -> Dictionary:
	var dir_result := _ensure_profile_dir()
	if not bool(dir_result.get("ok", false)):
		return dir_result
	var file := FileAccess.open(PROFILE_PATH, FileAccess.WRITE)
	if file == null:
		return {
			"ok": false,
			"reason": "open_failed",
			"error": FileAccess.get_open_error(),
		}
	file.store_string(JSON.stringify(profile, "\t"))
	file.close()
	return {"ok": true, "path": PROFILE_PATH}

func load_profile() -> Dictionary:
	if not has_profile():
		return {}
	var file := FileAccess.open(PROFILE_PATH, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	return parsed if parsed is Dictionary else {}

func has_profile() -> bool:
	return FileAccess.file_exists(PROFILE_PATH)

func delete_profile_debug_only() -> Dictionary:
	if not has_profile():
		return {"ok": true, "deleted": false}
	var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(PROFILE_PATH))
	return {"ok": err == OK, "deleted": err == OK, "error": err}

func _ensure_profile_dir() -> Dictionary:
	var err := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PROFILE_DIR))
	return {"ok": err == OK or err == ERR_ALREADY_EXISTS, "reason": "mkdir_failed", "error": err}
