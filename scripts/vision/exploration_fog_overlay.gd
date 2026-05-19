class_name ExplorationFogOverlay
extends Sprite2D

@export var mask_pixel_world_size: float = 128.0
@export var explored_alpha: float = 0.5
@export var unexplored_alpha: float = 1.0
@export var current_softness_px: float = 220.0
@export var dissolve_strength: float = 0.22
@export var reveal_move_threshold_px: float = 96.0
@export var persistent_edge_softness_px: float = 160.0

var target: Node2D
var map_bounds: Rect2 = Rect2()
var current_radius: float = 1280.0

var _image: Image
var _texture: ImageTexture
var _shader_material: ShaderMaterial
var _texture_size: Vector2i = Vector2i.ZERO
var _last_reveal_position: Vector2 = Vector2.ZERO
var _has_last_reveal_position: bool = false

func _ready() -> void:
	centered = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	z_as_relative = false
	z_index = 800
	_create_shader()
	set_process(true)

func setup(bounds: Rect2, p_target: Node2D, initial_radius: float) -> void:
	map_bounds = bounds
	target = p_target
	current_radius = maxf(0.0, initial_radius)
	if _shader_material == null:
		_create_shader()
	_create_mask_texture()
	_update_shader_parameters()
	if target != null:
		reveal_circle(target.global_position, current_radius)

func set_radius(value: float) -> void:
	current_radius = maxf(0.0, value)
	_update_shader_parameters()
	if target != null:
		reveal_circle(target.global_position, current_radius)

func set_darkness_enabled(value: bool) -> void:
	visible = value

func reveal_circle(world_center: Vector2, radius_px: float) -> void:
	if _image == null or _texture == null or map_bounds.size.x <= 0.0 or map_bounds.size.y <= 0.0:
		return
	var radius := maxf(0.0, radius_px)
	var soft := maxf(0.0, persistent_edge_softness_px)
	var reveal_bounds := Rect2(world_center - Vector2.ONE * (radius + soft), Vector2.ONE * (radius + soft) * 2.0)
	var pixel_rect := _world_rect_to_pixel_rect(reveal_bounds)
	var changed := false
	for y in range(pixel_rect.position.y, pixel_rect.position.y + pixel_rect.size.y):
		for x in range(pixel_rect.position.x, pixel_rect.position.x + pixel_rect.size.x):
			var world_pos := _pixel_to_world_center(x, y)
			var dist := world_pos.distance_to(world_center)
			var reveal := 1.0
			if soft > 0.0:
				reveal = 1.0 - smoothstep(radius, radius + soft, dist)
			elif dist > radius:
				reveal = 0.0
			if reveal <= 0.0:
				continue
			changed = _set_explored_pixel(x, y, reveal) or changed
	if changed:
		_texture.update(_image)

func reveal_rect(world_rect: Rect2, edge_softness_px: float = -1.0) -> void:
	_reveal_rect_channel(world_rect, 0, edge_softness_px)

func reveal_permanent_light_rect(world_rect: Rect2, edge_softness_px: float = -1.0) -> void:
	_reveal_rect_channel(world_rect, 1, edge_softness_px)

func _reveal_rect_channel(world_rect: Rect2, channel: int, edge_softness_px: float = -1.0) -> void:
	if _image == null or _texture == null or world_rect.size.x <= 0.0 or world_rect.size.y <= 0.0:
		return
	var soft := persistent_edge_softness_px if edge_softness_px < 0.0 else maxf(0.0, edge_softness_px)
	var reveal_bounds := world_rect.grow(soft)
	var pixel_rect := _world_rect_to_pixel_rect(reveal_bounds)
	var changed := false
	for y in range(pixel_rect.position.y, pixel_rect.position.y + pixel_rect.size.y):
		for x in range(pixel_rect.position.x, pixel_rect.position.x + pixel_rect.size.x):
			var world_pos := _pixel_to_world_center(x, y)
			var reveal := 1.0
			if not world_rect.has_point(world_pos):
				reveal = 1.0 - smoothstep(0.0, soft, _distance_to_rect(world_pos, world_rect)) if soft > 0.0 else 0.0
			if reveal <= 0.0:
				continue
			changed = _set_mask_pixel_channel(x, y, channel, reveal) or changed
	if changed:
		_texture.update(_image)

func get_explored_value(world_pos: Vector2) -> float:
	if _image == null or _texture_size.x <= 0 or _texture_size.y <= 0 or not map_bounds.has_point(world_pos):
		return 0.0
	var pixel := _world_to_pixel(world_pos)
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= _texture_size.x or pixel.y >= _texture_size.y:
		return 0.0
	return _image.get_pixel(pixel.x, pixel.y).r

func get_permanent_light_value(world_pos: Vector2) -> float:
	if _image == null or _texture_size.x <= 0 or _texture_size.y <= 0 or not map_bounds.has_point(world_pos):
		return 0.0
	var pixel := _world_to_pixel(world_pos)
	if pixel.x < 0 or pixel.y < 0 or pixel.x >= _texture_size.x or pixel.y >= _texture_size.y:
		return 0.0
	return _image.get_pixel(pixel.x, pixel.y).g

func _process(_delta: float) -> void:
	if target == null or _image == null:
		return
	_update_shader_parameters()
	if not _has_last_reveal_position or target.global_position.distance_to(_last_reveal_position) >= reveal_move_threshold_px:
		reveal_circle(target.global_position, current_radius)
		_last_reveal_position = target.global_position
		_has_last_reveal_position = true

func _create_mask_texture() -> void:
	var width := maxi(1, int(ceil(map_bounds.size.x / maxf(1.0, mask_pixel_world_size))))
	var height := maxi(1, int(ceil(map_bounds.size.y / maxf(1.0, mask_pixel_world_size))))
	_texture_size = Vector2i(width, height)
	_image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0.0, 0.0, 0.0, 1.0))
	_texture = ImageTexture.create_from_image(_image)
	texture = _texture
	position = map_bounds.position
	scale = Vector2(map_bounds.size.x / float(width), map_bounds.size.y / float(height))

func _create_shader() -> void:
	_shader_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec2 map_size_px = vec2(1.0, 1.0);
uniform vec2 current_center_uv = vec2(0.5, 0.5);
uniform float current_radius_px = 1280.0;
uniform float current_softness_px = 220.0;
uniform float explored_alpha = 0.5;
uniform float unexplored_alpha = 1.0;
uniform float dissolve_strength = 0.22;

float hash21(vec2 p) {
	p = floor(p);
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void fragment() {
	vec4 mask = texture(TEXTURE, UV);
	float explored = mask.r;
	float permanent_light = mask.g;
	vec2 pixel = UV * map_size_px;
	vec2 center = current_center_uv * map_size_px;
	float noise = hash21(pixel / 96.0) - 0.5;
	float pulse = 1.0 + sin(TIME * 2.1) * 0.035;
	float softness = max(1.0, current_softness_px * pulse);
	float dist = distance(pixel, center) + noise * softness * dissolve_strength;
	float current_light = 1.0 - smoothstep(current_radius_px - softness, current_radius_px + softness, dist);
	float base_alpha = mix(unexplored_alpha, explored_alpha, explored);
	float alpha = mix(base_alpha, 0.0, current_light);
	alpha = mix(alpha, 0.0, permanent_light);
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	_shader_material.shader = shader
	material = _shader_material

func _update_shader_parameters() -> void:
	if _shader_material == null or map_bounds.size.x <= 0.0 or map_bounds.size.y <= 0.0:
		return
	var center_uv := Vector2(0.5, 0.5)
	if target != null:
		center_uv = (target.global_position - map_bounds.position) / map_bounds.size
		center_uv = Vector2(clampf(center_uv.x, 0.0, 1.0), clampf(center_uv.y, 0.0, 1.0))
	_shader_material.set_shader_parameter("map_size_px", map_bounds.size)
	_shader_material.set_shader_parameter("current_center_uv", center_uv)
	_shader_material.set_shader_parameter("current_radius_px", current_radius)
	_shader_material.set_shader_parameter("current_softness_px", current_softness_px)
	_shader_material.set_shader_parameter("explored_alpha", explored_alpha)
	_shader_material.set_shader_parameter("unexplored_alpha", unexplored_alpha)
	_shader_material.set_shader_parameter("dissolve_strength", dissolve_strength)

func _world_rect_to_pixel_rect(world_rect: Rect2) -> Rect2i:
	var clipped := world_rect.intersection(map_bounds)
	if clipped.size.x <= 0.0 or clipped.size.y <= 0.0:
		return Rect2i()
	var min_pixel := _world_to_pixel(clipped.position)
	var max_pixel := _world_to_pixel(clipped.end) + Vector2i.ONE
	min_pixel.x = clampi(min_pixel.x, 0, _texture_size.x)
	min_pixel.y = clampi(min_pixel.y, 0, _texture_size.y)
	max_pixel.x = clampi(max_pixel.x, 0, _texture_size.x)
	max_pixel.y = clampi(max_pixel.y, 0, _texture_size.y)
	return Rect2i(min_pixel, max_pixel - min_pixel)

func _world_to_pixel(world_pos: Vector2) -> Vector2i:
	var uv := (world_pos - map_bounds.position) / map_bounds.size
	return Vector2i(
		int(floor(uv.x * float(_texture_size.x))),
		int(floor(uv.y * float(_texture_size.y)))
	)

func _pixel_to_world_center(x: int, y: int) -> Vector2:
	return map_bounds.position + Vector2(
		(float(x) + 0.5) / float(_texture_size.x) * map_bounds.size.x,
		(float(y) + 0.5) / float(_texture_size.y) * map_bounds.size.y
	)

func _set_explored_pixel(x: int, y: int, value: float) -> bool:
	return _set_mask_pixel_channel(x, y, 0, value)

func _set_mask_pixel_channel(x: int, y: int, channel: int, value: float) -> bool:
	if x < 0 or y < 0 or x >= _texture_size.x or y >= _texture_size.y:
		return false
	var current := _image.get_pixel(x, y)
	var current_value := current.r if channel == 0 else current.g
	var next_value := maxf(current_value, clampf(value, 0.0, 1.0))
	if next_value <= current_value + 0.001:
		return false
	if channel == 0:
		current.r = next_value
	else:
		current.g = next_value
		current.r = maxf(current.r, next_value)
	_image.set_pixel(x, y, current)
	return true

func _distance_to_rect(point: Vector2, rect: Rect2) -> float:
	var dx := maxf(maxf(rect.position.x - point.x, 0.0), point.x - rect.end.x)
	var dy := maxf(maxf(rect.position.y - point.y, 0.0), point.y - rect.end.y)
	return Vector2(dx, dy).length()
