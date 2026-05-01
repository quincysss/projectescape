class_name VisionMaskOverlay
extends ColorRect

var target: Node2D
var radius: float = 1280.0
var darkness_enabled: bool = false

var _shader_material: ShaderMaterial

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_resize_to_viewport()
	get_viewport().size_changed.connect(_resize_to_viewport)
	color = Color.BLACK
	_shader_material = ShaderMaterial.new()
	var shader := Shader.new()
	shader.code = """
shader_type canvas_item;

uniform vec2 center = vec2(0.0, 0.0);
uniform float radius = 1280.0;
uniform float softness = 18.0;
uniform float darkness = 1.0;

void fragment() {
	float dist = distance(FRAGCOORD.xy, center);
	float alpha = smoothstep(radius - softness, radius + softness, dist) * darkness;
	COLOR = vec4(0.0, 0.0, 0.0, alpha);
}
"""
	_shader_material.shader = shader
	material = _shader_material
	visible = false
	call_deferred("_update_shader")

func _process(_delta: float) -> void:
	if darkness_enabled:
		_update_shader()

func set_radius(value: float) -> void:
	radius = maxf(0.0, value)
	_update_shader()

func set_darkness_enabled(value: bool) -> void:
	darkness_enabled = value
	visible = value
	_update_shader()

func _update_shader() -> void:
	if _shader_material == null or not is_inside_tree():
		return
	_resize_to_viewport()
	var center := get_viewport_rect().size * 0.5
	if target:
		center = target.get_global_transform_with_canvas().origin
	_shader_material.set_shader_parameter("center", center)
	_shader_material.set_shader_parameter("radius", _get_screen_radius())

func _resize_to_viewport() -> void:
	position = Vector2.ZERO
	size = get_viewport_rect().size

func _get_screen_radius() -> float:
	if target == null:
		return radius
	var canvas_scale := target.get_global_transform_with_canvas().get_scale()
	var zoom_scale: float = (absf(canvas_scale.x) + absf(canvas_scale.y)) * 0.5
	return radius * zoom_scale
