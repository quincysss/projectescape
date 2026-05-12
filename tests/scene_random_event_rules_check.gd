extends SceneTree

const SceneRandomEventDirectorScript := preload("res://scripts/events/scene_random_event_director.gd")

class DummyGameState:
	extends Node
	var day: int = 1
	func get_current_day() -> int:
		return day

func _initialize() -> void:
	var ok := _verify_scene_random_event_rules()
	print("Scene random event rules verified." if ok else "Scene random event rules failed.")
	quit(0 if ok else 1)

func _verify_scene_random_event_rules() -> bool:
	var director = SceneRandomEventDirectorScript.new()
	if not director.load_config():
		printerr("Expected scene random event config to load: %s" % str(director.load_errors))
		return false
	var dummy := DummyGameState.new()
	dummy.day = 1
	var day_one = director.resolve_for_run(dummy, 300.0, 12345, {})
	if day_one.monster_event_active:
		printerr("Day 1 should not naturally activate monsters.")
		return false
	dummy.day = 2
	var day_two = director.resolve_for_run(dummy, 300.0, 12345, {})
	if day_two.monster_event_active:
		printerr("Day 2 should not naturally activate monsters.")
		return false
	dummy.day = 3
	var day_three = director.resolve_for_run(dummy, 300.0, 12345, {})
	if not day_three.monster_event_active:
		printerr("Day 3 should guarantee monster_presence.")
		return false
	if day_three.monster_spawn_count != 4:
		printerr("Monster event should request 4 monsters, got %s." % day_three.monster_spawn_count)
		return false
	dummy.day = 1
	var forced = director.resolve_for_run(dummy, 300.0, 12345, {"monster_presence": true})
	if not forced.monster_event_active:
		printerr("GM forced monster_presence should activate even before day 3.")
		return false
	return true
