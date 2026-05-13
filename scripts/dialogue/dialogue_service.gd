class_name DialogueService
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")

func load_sequence(path: String) -> Dictionary:
	var request := _parse_sequence_request(path)
	var file_path := String(request.get("path", ""))
	var requested_dialogue_id := String(request.get("dialogue_id", ""))
	if file_path.is_empty():
		return {}
	if file_path.get_extension().to_lower() == "tab":
		return _load_sequence_from_tab(file_path, requested_dialogue_id)
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	return _normalize_sequence(parsed if parsed is Dictionary else {})

func _parse_sequence_request(path: String) -> Dictionary:
	var marker_index := path.find("#")
	if marker_index < 0:
		return {"path": path, "dialogue_id": ""}
	return {
		"path": path.substr(0, marker_index),
		"dialogue_id": path.substr(marker_index + 1),
	}

func _load_sequence_from_tab(path: String, dialogue_id: String) -> Dictionary:
	if dialogue_id.is_empty():
		return {}
	var loader = TabDataLoaderScript.new()
	var rows: Array[Dictionary] = []
	for row in loader.load_tab(path):
		if String(row.get("dialogue_id", "")) != dialogue_id:
			continue
		if not TabDataLoader.parse_bool(String(row.get("enabled", "true")), true):
			continue
		rows.append(row)
	if rows.is_empty():
		return {}
	rows.sort_custom(func(a, b): return int(a.get("order", 0)) < int(b.get("order", 0)))
	var sequence := {
		"dialogue_id": dialogue_id,
		"skippable": TabDataLoader.parse_bool(String(rows[0].get("skippable", "true")), true),
		"entries": [],
	}
	for row in rows:
		sequence["entries"].append({
			"speaker_id": String(row.get("speaker_id", "")),
			"speaker_name": String(row.get("speaker_name", row.get("speaker_id", ""))),
			"text": String(row.get("text", "")),
		})
	return _normalize_sequence(sequence)

func _normalize_sequence(sequence: Dictionary) -> Dictionary:
	if sequence.is_empty():
		return {}
	var entries: Array = []
	for entry in Array(sequence.get("entries", [])):
		if not (entry is Dictionary):
			continue
		var entry_dict: Dictionary = entry
		entries.append({
			"speaker_id": String(entry_dict.get("speaker_id", "")),
			"speaker_name": String(entry_dict.get("speaker_name", entry_dict.get("speaker_id", ""))),
			"text": String(entry_dict.get("text", "")),
		})
	sequence["entries"] = entries
	sequence["dialogue_id"] = String(sequence.get("dialogue_id", ""))
	sequence["skippable"] = bool(sequence.get("skippable", true))
	return sequence
