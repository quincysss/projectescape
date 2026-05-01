class_name SafeZone
extends Area2D

signal safe_zone_entered(zone_id: StringName, zone_type: StringName)
signal safe_zone_exited(zone_id: StringName, zone_type: StringName)

@export var zone_id: StringName = &"safe_zone"
@export_enum("home", "outpost") var zone_type: String = "home"
@export var is_active: bool = true
@export var restore_stability: bool = true
@export var allow_storage: bool = false
@export var allow_extraction: bool = false

var _tracked_bodies: Array[Node] = []

func _ready() -> void:
	add_to_group("safe_zones")
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func can_show_overview_signals() -> bool:
	return false

func can_store_items() -> bool:
	return allow_storage and is_active

func can_extract(extraction_unlocked: bool = false) -> bool:
	return allow_extraction and is_active and extraction_unlocked

func debug_enter() -> void:
	if not is_active:
		return
	safe_zone_entered.emit(zone_id, StringName(zone_type))

func debug_exit() -> void:
	if not is_active:
		return
	safe_zone_exited.emit(zone_id, StringName(zone_type))

func _on_body_entered(body: Node) -> void:
	if not is_active or not _is_player_body(body):
		return
	if _tracked_bodies.has(body):
		return
	_tracked_bodies.append(body)
	safe_zone_entered.emit(zone_id, StringName(zone_type))

func _on_body_exited(body: Node) -> void:
	if not _tracked_bodies.has(body):
		return
	_tracked_bodies.erase(body)
	if is_active:
		safe_zone_exited.emit(zone_id, StringName(zone_type))

func _is_player_body(body: Node) -> bool:
	return body.is_in_group("player") or body.name == "Player"
