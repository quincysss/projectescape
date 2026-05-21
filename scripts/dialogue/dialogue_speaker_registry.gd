class_name DialogueSpeakerRegistry
extends RefCounted

const TabDataLoaderScript := preload("res://scripts/data/tab_data_loader.gd")
const SPEAKER_TABLE_PATH := "res://setting/dialogue_speakers.tab"
const PLACEHOLDER_PORTRAIT_PATH := "res://assets/characters/dialogue/common/dialogue_portrait_placeholder.png"

var _loaded := false
var _speakers: Dictionary = {}

func get_speaker(speaker_id: String) -> Dictionary:
	_ensure_loaded()
	var id := speaker_id.strip_edges()
	var speaker := (_speakers.get(id, {}) as Dictionary).duplicate()
	if speaker.is_empty():
		speaker = _fallback_speaker(id)
	speaker["speaker_id"] = id
	speaker["portrait_side"] = _normalized_side(String(speaker.get("portrait_side", "")), id)
	speaker["portrait_path"] = _resolved_portrait_path(id, String(speaker.get("portrait_path", "")))
	speaker["nameplate_color_value"] = _resolved_nameplate_color(String(speaker.get("nameplate_color", "")))
	return speaker

func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_speakers.clear()
	var loader = TabDataLoaderScript.new()
	for row in loader.load_tab(SPEAKER_TABLE_PATH):
		var speaker_id := String(row.get("speaker_id", "")).strip_edges()
		if speaker_id.is_empty():
			continue
		_speakers[speaker_id] = {
			"display_name": String(row.get("display_name", speaker_id)),
			"portrait_path": String(row.get("portrait_path", "")),
			"portrait_side": String(row.get("portrait_side", "")),
			"nameplate_color": String(row.get("nameplate_color", "")),
		}

func _fallback_speaker(speaker_id: String) -> Dictionary:
	return {
		"display_name": speaker_id,
		"portrait_path": PLACEHOLDER_PORTRAIT_PATH,
		"portrait_side": "left",
		"nameplate_color": "#EFEDEA",
	}

func _normalized_side(side: String, _speaker_id: String) -> String:
	var lower := side.strip_edges().to_lower()
	if lower == "left" or lower == "right":
		return "left"
	return "left"

func _resolved_portrait_path(speaker_id: String, portrait_path: String) -> String:
	var path := portrait_path.strip_edges()
	if not path.is_empty() and ResourceLoader.exists(path):
		return path
	if OS.is_debug_build():
		push_warning("Dialogue speaker '%s' portrait missing: %s. Using placeholder." % [speaker_id, path])
	return PLACEHOLDER_PORTRAIT_PATH

func _resolved_nameplate_color(color_text: String) -> Color:
	var text := color_text.strip_edges()
	if text.is_empty():
		return Color("#EFEDEA")
	return Color(text)
