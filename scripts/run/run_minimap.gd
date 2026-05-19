class_name RunMinimap
extends Control

const OUTER_SIZE := Vector2(188.0, 188.0)
const INNER_RADIUS := 82.0
const BORDER_RADIUS := 88.0
const REDRAW_INTERVAL_MSEC := 50
const LOCAL_VIEW_RADIUS_PX := 3600.0
const FOG_SAMPLE_STEP := 4.0

var map_bounds: Rect2 = Rect2()
var fog_overlay
var player: Node2D
var current_radius: float = 0.0
var markers: Array[Dictionary] = []
var _last_redraw_msec: int = 0

func _ready() -> void:
	size = OUTER_SIZE
	custom_minimum_size = OUTER_SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_from_scene(scene) -> void:
	if scene == null:
		return
	if scene.has_method("_map_bounds_px"):
		map_bounds = scene._map_bounds_px()
	fog_overlay = scene.vision_mask
	player = scene.player
	current_radius = (
		scene.run_director.vision_controller.current_radius
		if scene.run_director != null and scene.run_director.vision_controller != null
		else 0.0
	)
	markers = _collect_markers(scene)
	var now := Time.get_ticks_msec()
	if _last_redraw_msec == 0 or now - _last_redraw_msec >= REDRAW_INTERVAL_MSEC:
		_last_redraw_msec = now
		queue_redraw()

func get_marker_count(marker_type: String) -> int:
	var count := 0
	for marker in markers:
		if String(marker.get("type", "")) == marker_type:
			count += 1
	return count

func _collect_markers(scene) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if scene.outpost_root == null:
		return result
	for child in scene.outpost_root.get_children():
		if not is_instance_valid(child) or not (child is Node2D):
			continue
		var interact_type := ""
		if child.get_script() != null:
			interact_type = String(child.get("interact_type"))
		match interact_type:
			"outpost":
				var payload: Dictionary = child.get("payload")
				result.append({
					"type": "outpost",
					"position": child.global_position,
					"repaired": bool(payload.get("repaired", false)),
				})
			"material":
				result.append({
					"type": "material",
					"position": child.global_position,
				})
	return result

func _draw() -> void:
	if map_bounds.size.x <= 0.0 or map_bounds.size.y <= 0.0:
		return
	var center := size * 0.5
	draw_circle(center, BORDER_RADIUS, Color(0.02, 0.022, 0.02, 0.86))
	draw_circle(center, INNER_RADIUS, Color(0.12, 0.15, 0.13, 0.94))
	_draw_local_base_layer(center)
	_draw_exploration_layer(center)
	_draw_current_player_vision(center)
	_draw_markers(center)
	_draw_player(center)
	draw_arc(center, BORDER_RADIUS, 0.0, TAU, 96, Color(0.78, 0.64, 0.28, 0.95), 2.5, true)
	draw_arc(center, INNER_RADIUS, 0.0, TAU, 96, Color(0.02, 0.02, 0.018, 0.9), 2.0, true)

func _draw_exploration_layer(center: Vector2) -> void:
	if fog_overlay == null or not is_instance_valid(fog_overlay):
		draw_circle(center, INNER_RADIUS, Color(0.0, 0.0, 0.0, 0.85))
		return
	var image = fog_overlay.get("_image")
	if image == null:
		draw_circle(center, INNER_RADIUS, Color(0.0, 0.0, 0.0, 0.85))
		return
	var radius := FOG_SAMPLE_STEP * 0.72
	var start := center - Vector2.ONE * INNER_RADIUS
	var end := center + Vector2.ONE * INNER_RADIUS
	var y := start.y
	while y <= end.y:
		var x := start.x
		while x <= end.x:
			var pos := Vector2(x, y)
			if pos.distance_to(center) > INNER_RADIUS - radius:
				x += FOG_SAMPLE_STEP
				continue
			var world_pos := _minimap_to_world(pos)
			var explored := 0.0
			var permanent_light := 0.0
			if map_bounds.has_point(world_pos):
				explored = clampf(float(fog_overlay.call("get_explored_value", world_pos)), 0.0, 1.0)
				if fog_overlay.has_method("get_permanent_light_value"):
					permanent_light = clampf(float(fog_overlay.call("get_permanent_light_value", world_pos)), 0.0, 1.0)
			var alpha := lerpf(1.0, 0.5, explored)
			alpha = lerpf(alpha, 0.0, _current_vision_strength(world_pos))
			alpha = lerpf(alpha, 0.0, permanent_light)
			if alpha > 0.02:
				draw_circle(pos, radius, Color(0.0, 0.0, 0.0, alpha))
			x += FOG_SAMPLE_STEP
		y += FOG_SAMPLE_STEP

func _draw_local_base_layer(center: Vector2) -> void:
	var grid_spacing_px := 512.0 * _map_scale()
	if grid_spacing_px <= 2.0:
		return
	var anchor := _minimap_anchor_world()
	var origin_offset := Vector2(
		fposmod(anchor.x, 512.0) * _map_scale(),
		fposmod(anchor.y, 512.0) * _map_scale()
	)
	var line_color := Color(0.24, 0.28, 0.24, 0.18)
	var x := center.x - origin_offset.x
	while x > center.x - INNER_RADIUS:
		x -= grid_spacing_px
	while x <= center.x + INNER_RADIUS:
		var half_height := sqrt(maxf(0.0, INNER_RADIUS * INNER_RADIUS - pow(x - center.x, 2.0)))
		draw_line(Vector2(x, center.y - half_height), Vector2(x, center.y + half_height), line_color, 1.0, true)
		x += grid_spacing_px
	var y := center.y - origin_offset.y
	while y > center.y - INNER_RADIUS:
		y -= grid_spacing_px
	while y <= center.y + INNER_RADIUS:
		var half_width := sqrt(maxf(0.0, INNER_RADIUS * INNER_RADIUS - pow(y - center.y, 2.0)))
		draw_line(Vector2(center.x - half_width, y), Vector2(center.x + half_width, y), line_color, 1.0, true)
		y += grid_spacing_px

func _draw_current_player_vision(center: Vector2) -> void:
	if player == null or not is_instance_valid(player) or current_radius <= 0.0:
		return
	var pos := _world_to_minimap(player.global_position)
	if pos.distance_to(center) > INNER_RADIUS + 12.0:
		return
	draw_circle(pos, current_radius * _map_scale(), Color(0.95, 0.88, 0.54, 0.08))
	draw_arc(pos, current_radius * _map_scale(), 0.0, TAU, 48, Color(0.95, 0.82, 0.36, 0.26), 1.2, true)

func _draw_markers(center: Vector2) -> void:
	for marker in markers:
		var pos := _world_to_minimap(marker.get("position", Vector2.ZERO))
		if pos.distance_to(center) > INNER_RADIUS - 4.0:
			pos = center + (pos - center).normalized() * (INNER_RADIUS - 4.0)
		match String(marker.get("type", "")):
			"outpost":
				var repaired := bool(marker.get("repaired", false))
				var color := Color(0.42, 0.95, 0.52, 0.98) if repaired else Color(1.0, 0.68, 0.23, 0.98)
				var points := PackedVector2Array([
					pos + Vector2(0.0, -7.0),
					pos + Vector2(7.0, 0.0),
					pos + Vector2(0.0, 7.0),
					pos + Vector2(-7.0, 0.0),
				])
				draw_colored_polygon(points, color)
				draw_polyline(points + PackedVector2Array([points[0]]), Color(0.02, 0.018, 0.012, 0.9), 1.5, true)
			"material":
				draw_circle(pos, 4.0, Color(0.48, 0.95, 1.0, 0.98))
				draw_arc(pos, 4.8, 0.0, TAU, 20, Color(0.02, 0.05, 0.05, 0.9), 1.2, true)

func _draw_player(center: Vector2) -> void:
	if player == null or not is_instance_valid(player):
		return
	var pos := _world_to_minimap(player.global_position)
	if pos.distance_to(center) > INNER_RADIUS - 3.0:
		pos = center + (pos - center).normalized() * (INNER_RADIUS - 3.0)
	draw_circle(pos, 5.0, Color(0.94, 0.96, 0.88, 1.0))
	draw_arc(pos, 6.2, 0.0, TAU, 24, Color(0.02, 0.02, 0.018, 0.92), 1.3, true)

func _mask_pixel_world_center(x: int, y: int, width: int, height: int) -> Vector2:
	return map_bounds.position + Vector2(
		(float(x) + 0.5) / float(width) * map_bounds.size.x,
		(float(y) + 0.5) / float(height) * map_bounds.size.y
	)

func _world_to_minimap(world_pos: Vector2) -> Vector2:
	var center := size * 0.5
	var offset := world_pos - _minimap_anchor_world()
	return center + offset * _map_scale()

func _minimap_to_world(minimap_pos: Vector2) -> Vector2:
	return _minimap_anchor_world() + (minimap_pos - size * 0.5) / _map_scale()

func _minimap_anchor_world() -> Vector2:
	if player != null and is_instance_valid(player):
		return player.global_position
	return map_bounds.get_center()

func _map_scale() -> float:
	return INNER_RADIUS / LOCAL_VIEW_RADIUS_PX

func _current_vision_strength(world_pos: Vector2) -> float:
	if player == null or not is_instance_valid(player) or current_radius <= 0.0:
		return 0.0
	var softness := 220.0
	if fog_overlay != null and is_instance_valid(fog_overlay):
		softness = float(fog_overlay.get("current_softness_px"))
	var dist := world_pos.distance_to(player.global_position)
	return 1.0 - smoothstep(maxf(0.0, current_radius - softness), current_radius + softness, dist)
