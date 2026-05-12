class_name SaveStorageAdapter
extends RefCounted

func save_profile(_profile: Dictionary) -> Dictionary:
	return {"ok": false, "reason": "not_implemented"}

func load_profile() -> Dictionary:
	return {}

func has_profile() -> bool:
	return false

func delete_profile_debug_only() -> Dictionary:
	return {"ok": false, "reason": "not_implemented"}
