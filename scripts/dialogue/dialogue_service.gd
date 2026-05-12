class_name DialogueService
extends RefCounted

func load_sequence(path: String) -> Dictionary:
	if path.is_empty() or not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var content := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(content)
	return _normalize_sequence(parsed if parsed is Dictionary else {})

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
