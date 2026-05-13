extends SceneTree

const RunSceneScript := preload("res://scripts/run/run_scene.gd")


func _initialize() -> void:
	var ok := _verify_default_status_prompt_timeout()
	ok = _verify_repeated_status_prompt_restarts_timeout() and ok
	ok = _verify_custom_status_prompt_timeout_is_preserved() and ok
	print("Run status prompt timeout verified." if ok else "Run status prompt timeout failed.")
	quit(0 if ok else 1)


func _verify_default_status_prompt_timeout() -> bool:
	var scene = RunSceneScript.new()
	scene._status_prompt = "需要先修复两座前哨站。"
	scene._update_status_prompt_timeout()
	var clear_time: int = int(scene._status_prompt_clear_time_msec)
	var now := Time.get_ticks_msec()
	if scene._timed_status_prompt_text != scene._status_prompt:
		printerr("Expected status prompt text to become the timed prompt.")
		scene.queue_free()
		return false
	if clear_time < now + 2900 or clear_time > now + 3100:
		printerr("Expected default status prompt timeout near 3 seconds, got %d ms." % (clear_time - now))
		scene.queue_free()
		return false
	scene._status_prompt_clear_time_msec = Time.get_ticks_msec() - 1
	scene._update_status_prompt_timeout()
	if not scene._status_prompt.is_empty():
		printerr("Expected expired status prompt to be cleared.")
		scene.queue_free()
		return false
	scene.queue_free()
	return true


func _verify_repeated_status_prompt_restarts_timeout() -> bool:
	var scene = RunSceneScript.new()
	scene._status_prompt = "需要先修复两座前哨站。"
	scene._update_status_prompt_timeout()
	scene._status_prompt_clear_time_msec = Time.get_ticks_msec() + 10
	scene._status_prompt = "需要先修复两座前哨站。"
	scene._update_status_prompt_timeout()
	var remaining_ms := int(scene._status_prompt_clear_time_msec) - Time.get_ticks_msec()
	if remaining_ms < 2900:
		printerr("Expected repeated status prompt to restart the 3 second timeout, got %d ms." % remaining_ms)
		scene.queue_free()
		return false
	scene.queue_free()
	return true


func _verify_custom_status_prompt_timeout_is_preserved() -> bool:
	var scene = RunSceneScript.new()
	scene._set_timed_status_prompt("前哨材料已获得。", 1.8)
	var clear_time: int = int(scene._status_prompt_clear_time_msec)
	var now := Time.get_ticks_msec()
	scene._update_status_prompt_timeout()
	var preserved_clear_time: int = int(scene._status_prompt_clear_time_msec)
	if preserved_clear_time != clear_time:
		printerr("Expected custom timed status prompt to preserve its timeout.")
		scene.queue_free()
		return false
	if preserved_clear_time < now + 1700 or preserved_clear_time > now + 1900:
		printerr("Expected custom status prompt timeout near 1.8 seconds, got %d ms." % (preserved_clear_time - now))
		scene.queue_free()
		return false
	scene.queue_free()
	return true
