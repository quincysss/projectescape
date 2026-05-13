class_name DialoguePortraitController
extends RefCounted

const ACTIVE_ALPHA := 1.0
const PLACEHOLDER_PORTRAIT_PATH := "res://assets/characters/dialogue/common/dialogue_portrait_placeholder.png"

var speaker_registry: RefCounted
var left_portrait: TextureRect
var right_portrait: TextureRect

func setup(registry: RefCounted, left_view: TextureRect, right_view: TextureRect) -> void:
	speaker_registry = registry
	left_portrait = left_view
	right_portrait = right_view
	hide_all()

func update_for_entry(entry: Dictionary, sequence_speaker_ids: Array[String], viewport_size: Vector2) -> void:
	if speaker_registry == null:
		return
	var active_id := String(entry.get("speaker_id", "")).strip_edges()
	hide_all()
	if active_id.is_empty():
		return
	var speaker: Dictionary = speaker_registry.call("get_speaker", active_id)
	_apply_active_portrait(active_id, speaker)

func hide_all() -> void:
	if left_portrait != null:
		left_portrait.visible = false
		left_portrait.modulate = Color(1.0, 1.0, 1.0, 0.0)
	if right_portrait != null:
		right_portrait.visible = false
		right_portrait.modulate = Color(1.0, 1.0, 1.0, 0.0)

func _apply_active_portrait(speaker_id: String, speaker: Dictionary) -> void:
	var view := right_portrait
	if view == null:
		return
	var portrait_path := String(speaker.get("portrait_path", PLACEHOLDER_PORTRAIT_PATH))
	var texture := load(portrait_path) as Texture2D
	view.texture = texture
	view.visible = texture != null
	view.modulate = Color(1.0, 1.0, 1.0, ACTIVE_ALPHA)
	view.z_index = 2
	view.set_meta("speaker_id", speaker_id)
