@tool
class_name OutpostVisualAnchor
extends Node2D

const BROKEN_TEXTURE := preload("res://assets/map/outposts/outpost_broken_01.png")
const REPAIRED_TEXTURE := preload("res://assets/map/outposts/outpost_repaired_01.png")
const PLAYER_ALWAYS_IN_FRONT_Z_INDEX := -1

@export var candidate_id: String = "":
	set(value):
		candidate_id = value
		update_configuration_warnings()
@export var broken_texture: Texture2D = BROKEN_TEXTURE:
	set(value):
		broken_texture = value
		if Engine.is_editor_hint():
			_apply_texture(preview_repaired)
@export var repaired_texture: Texture2D = REPAIRED_TEXTURE:
	set(value):
		repaired_texture = value
		if Engine.is_editor_hint():
			_apply_texture(preview_repaired)
@export var sprite_path: NodePath = NodePath("ArtSprite"):
	set(value):
		sprite_path = value
		update_configuration_warnings()
@export var keep_visible_when_not_selected: bool = true
@export var preview_repaired: bool = false:
	set(value):
		preview_repaired = value
		if Engine.is_editor_hint():
			_apply_texture(preview_repaired)

func _ready() -> void:
	add_to_group("outpost_visual_anchors")
	set_meta("player_always_in_front", true)
	set_meta("outpost_uses_normal_ysort", true)
	set_meta("occludes_player", false)
	z_index = PLAYER_ALWAYS_IN_FRONT_Z_INDEX
	if Engine.is_editor_hint():
		_apply_texture(preview_repaired)
	else:
		set_selected(false)

func get_candidate_id() -> String:
	if not candidate_id.is_empty():
		return candidate_id
	return name.trim_suffix("_Visual")

func set_selected(is_selected: bool) -> void:
	visible = is_selected or keep_visible_when_not_selected

func set_repaired(is_repaired: bool) -> void:
	_apply_texture(is_repaired)

func get_art_sprite() -> Sprite2D:
	return get_node_or_null(sprite_path) as Sprite2D

func _apply_texture(is_repaired: bool) -> void:
	var sprite := get_art_sprite()
	if sprite == null:
		return
	sprite.texture = repaired_texture if is_repaired else broken_texture

func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()
	if get_candidate_id().is_empty():
		warnings.append("candidate_id should match an OutpostCandidatePoint id.")
	if get_art_sprite() == null:
		warnings.append("Expected an ArtSprite child at sprite_path.")
	return warnings
