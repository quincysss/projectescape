class_name BlackTideBoundaryEssenceVisual
extends CharacterBody2D

@export var visual_scale: Vector2 = Vector2(1.05, 1.05)
@export var eye_focus_source_offset_px: Vector2 = Vector2(160.0, 40.0)
@export var idle_fps: float = 8.0

const IDLE_FRAME_COUNT := 8
const IDLE_FRAME_PATTERN := "res://assets/sprites/monsters/black_tide_boundary_essence/idle/frames/black_tide_boundary_essence_idle_8f_01_frame_%02d.png"

@onready var body_sprite: AnimatedSprite2D = $BodySprite
@onready var eye_focus: Marker2D = $EyeFocus
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var _facing_sign: float = 1.0

func _ready() -> void:
	add_to_group("monster_visual_assets")
	add_to_group("black_tide_boundary_essence")
	collision_layer = 0
	collision_mask = 0
	if collision_shape != null:
		collision_shape.disabled = true
	body_sprite.sprite_frames = _build_sprite_frames()
	body_sprite.centered = true
	_apply_visual_scale()
	body_sprite.play("idle")

func set_facing_direction(direction: Vector2) -> void:
	if direction.x > 0.05:
		_facing_sign = 1.0
	elif direction.x < -0.05:
		_facing_sign = -1.0
	body_sprite.flip_h = _facing_sign < 0.0
	_apply_visual_scale()

func _apply_visual_scale() -> void:
	body_sprite.scale = visual_scale
	var focus_position := Vector2(
		eye_focus_source_offset_px.x * visual_scale.x * _facing_sign,
		eye_focus_source_offset_px.y * visual_scale.y
	)
	eye_focus.position = focus_position
	collision_shape.position = focus_position

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", idle_fps)
	for index in range(1, IDLE_FRAME_COUNT + 1):
		var texture := load(IDLE_FRAME_PATTERN % index)
		if texture is Texture2D:
			frames.add_frame("idle", texture)
		else:
			push_warning("Missing black tide monster idle frame: %s" % (IDLE_FRAME_PATTERN % index))
	return frames
