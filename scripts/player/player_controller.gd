class_name PlayerController
extends CharacterBody2D

@export var base_speed: float = 180.0
@export var sprite_scale: Vector2 = Vector2(1.5, 1.5)

const IDLE_FRAME_COUNT := 8
const RUN_FRAME_COUNT := 9
const INTERACT_FRAME_COUNT := 4
const IDLE_FPS := 8.0
const RUN_FPS := 12.0
const INTERACT_FPS := 8.0
const SPRITE_FOOTLINE_Y := 244.0
const DIRECTIONS := ["down", "left", "right", "up"]

var speed_multiplier: float = 1.0
var walkable_rects: Array[Rect2] = []
var walkable_polygons: Array[PackedVector2Array] = []
var last_direction: String = "down"
var sprite: AnimatedSprite2D
var _is_interacting: bool = false
var _interaction_time_left: float = 0.0

func _ready() -> void:
	add_to_group("player")
	_setup_animation_sprite()

func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * base_speed * speed_multiplier
	if not _update_interaction_animation(_delta):
		_update_animation(input_vector)
	var previous_position := global_position
	move_and_slide()
	if not _is_position_walkable(global_position):
		global_position = previous_position
		velocity = Vector2.ZERO
		if not _is_interacting:
			_update_animation(Vector2.ZERO)

func set_walkable_rects(rects: Array[Rect2]) -> void:
	walkable_rects = rects

func set_walkable_polygons(polygons: Array[PackedVector2Array]) -> void:
	walkable_polygons = polygons

func face_towards(world_position: Vector2) -> void:
	var direction_vector := world_position - global_position
	if direction_vector.length_squared() > 0.001:
		last_direction = _direction_from_vector(direction_vector)

func _is_position_walkable(world_position: Vector2) -> bool:
	if walkable_rects.is_empty() and walkable_polygons.is_empty():
		return true
	for polygon in walkable_polygons:
		if Geometry2D.is_point_in_polygon(world_position, polygon):
			return true
	for rect in walkable_rects:
		if rect.has_point(world_position):
			return true
	return false

func _setup_animation_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.name = "PlayerSprite"
	sprite.sprite_frames = _build_sprite_frames()
	sprite.centered = true
	sprite.scale = sprite_scale
	sprite.position = Vector2(0.0, -(SPRITE_FOOTLINE_Y - 128.0) * sprite_scale.y)
	sprite.z_index = 30
	add_child(sprite)
	_play_animation("idle_down", false)

func _build_sprite_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for direction in DIRECTIONS:
		_add_animation(frames, "idle_%s" % direction, _idle_frame_paths(direction), IDLE_FPS)
	for direction in ["down", "left", "up"]:
		_add_animation(frames, "run_%s" % direction, _run_frame_paths(direction), RUN_FPS)
		_add_animation(frames, "interact_%s" % direction, _interact_frame_paths(direction), INTERACT_FPS)
	return frames

func _add_animation(frames: SpriteFrames, animation_name: String, paths: Array[String], fps: float) -> void:
	frames.add_animation(animation_name)
	frames.set_animation_loop(animation_name, true)
	frames.set_animation_speed(animation_name, fps)
	for path in paths:
		var texture := load(path)
		if texture is Texture2D:
			frames.add_frame(animation_name, texture)
		else:
			push_warning("Missing player animation frame: %s" % path)

func _idle_frame_paths(direction: String) -> Array[String]:
	var paths: Array[String] = []
	for index in range(1, IDLE_FRAME_COUNT + 1):
		paths.append("res://assets/sprites/player/male/idle/%s/frames/player_male_idle_%s_8f_01_frame_%02d.png" % [direction, direction, index])
	return paths

func _run_frame_paths(direction: String) -> Array[String]:
	var paths: Array[String] = []
	for index in range(1, RUN_FRAME_COUNT + 1):
		match direction:
			"left":
				paths.append("res://assets/sprites/player/male/run/left/frames/player_male_run_left_%02d.png" % index)
			"up":
				paths.append("res://assets/sprites/player/male/run/up/frame/player_male_idle_up_%02d.png" % index)
			"down":
				paths.append("res://assets/sprites/player/male/run/down/frame/player_male_idle_down_%02d.png" % index)
	return paths

func _interact_frame_paths(direction: String) -> Array[String]:
	var paths: Array[String] = []
	for index in range(1, INTERACT_FRAME_COUNT + 1):
		match direction:
			"left":
				paths.append("res://assets/sprites/player/male/interact/left/frame/player_male_idle_left_8f_01_frame_%02d.png" % index)
			"up":
				paths.append("res://assets/sprites/player/male/interact/up/frame/player_male_idle_up_%02d.png" % index)
			"down":
				paths.append("res://assets/sprites/player/male/interact/down/frame/player_male_idle_down_%02d.png" % (index + 2))
	return paths

func begin_interact_animation(looping: bool = true) -> void:
	_is_interacting = true
	_interaction_time_left = 0.0 if looping else float(INTERACT_FRAME_COUNT) / INTERACT_FPS
	_play_interact_animation(looping)

func play_interact_once() -> void:
	begin_interact_animation(false)

func end_interact_animation() -> void:
	_is_interacting = false
	_interaction_time_left = 0.0

func _update_interaction_animation(delta: float) -> bool:
	if not _is_interacting:
		return false
	if _interaction_time_left > 0.0:
		_interaction_time_left = maxf(0.0, _interaction_time_left - delta)
		if _interaction_time_left <= 0.0:
			end_interact_animation()
			return false
	return true

func _play_interact_animation(looping: bool) -> void:
	var animation_direction: String = "left" if last_direction == "right" else last_direction
	var flip_h: bool = last_direction == "right"
	var animation_name := "interact_%s" % animation_direction
	if sprite.sprite_frames.has_animation(animation_name):
		sprite.sprite_frames.set_animation_loop(animation_name, looping)
		sprite.flip_h = flip_h
		sprite.animation = animation_name
		sprite.frame = 0
		sprite.play()

func _update_animation(input_vector: Vector2) -> void:
	if sprite == null:
		return
	if input_vector.length_squared() > 0.001:
		last_direction = _direction_from_vector(input_vector)
		if last_direction == "left":
			_play_animation("run_left", true)
		elif last_direction == "right":
			_play_animation("run_left", false)
		else:
			_play_animation("run_%s" % last_direction, false)
	else:
		_play_animation("idle_%s" % last_direction, false)

func _direction_from_vector(input_vector: Vector2) -> String:
	if absf(input_vector.x) > absf(input_vector.y):
		return "right" if input_vector.x > 0.0 else "left"
	return "down" if input_vector.y > 0.0 else "up"

func _play_animation(animation_name: String, flip_h: bool) -> void:
	if sprite.animation == animation_name and sprite.flip_h == flip_h and sprite.is_playing():
		return
	sprite.flip_h = flip_h
	sprite.play(animation_name)
