extends SceneTree

const DialogueServiceScript := preload("res://scripts/dialogue/dialogue_service.gd")

func _initialize() -> void:
	var ok := _verify()
	print("Dialogue tab config verified." if ok else "Dialogue tab config failed.")
	quit(0 if ok else 1)

func _verify() -> bool:
	var service = DialogueServiceScript.new()
	var world_intro: Dictionary = service.load_sequence("res://setting/dialogues.tab#world_intro_dialogue")
	if world_intro.is_empty() or String(world_intro.get("dialogue_id", "")) != "world_intro_dialogue":
		printerr("Expected world_intro_dialogue to load from dialogues.tab.")
		return false
	if bool(world_intro.get("skippable", true)):
		printerr("Expected world_intro_dialogue to be non-skippable.")
		return false
	var world_entries: Array = Array(world_intro.get("entries", []))
	if world_entries.size() != 18:
		printerr("Expected 18 world intro entries, got %d." % world_entries.size())
		return false
	if String(Dictionary(world_entries[0]).get("text", "")) != "你回来了。":
		printerr("Expected world intro first line to come from current doc copy.")
		return false
	if not String(Dictionary(world_entries[5]).get("text", "")).contains("一切不起眼的物资"):
		printerr("Expected world intro to use the latest generic resource wording.")
		return false

	var first_departure: Dictionary = service.load_sequence("res://setting/dialogues.tab#first_departure_outpost_dialogue")
	if first_departure.is_empty() or bool(first_departure.get("skippable", true)):
		printerr("Expected first departure dialogue to load as non-skippable.")
		return false
	var departure_entries: Array = Array(first_departure.get("entries", []))
	if departure_entries.size() != 14:
		printerr("Expected 14 first departure entries, got %d." % departure_entries.size())
		return false
	if not String(Dictionary(departure_entries[4]).get("text", "")).contains("我们已经标成菱形信号"):
		printerr("Expected first departure dialogue to use current outpost repair wording.")
		return false

	var first_return: Dictionary = service.load_sequence("res://setting/dialogues.tab#first_return_chapter_1")
	if first_return.is_empty() or not bool(first_return.get("skippable", false)):
		printerr("Expected first return dialogue to load as skippable.")
		return false
	var return_entries: Array = Array(first_return.get("entries", []))
	if return_entries.size() != 10:
		printerr("Expected 10 first return entries, got %d." % return_entries.size())
		return false
	if not String(Dictionary(return_entries[4]).get("text", "")).contains("能卖的就换成矿币"):
		printerr("Expected first return dialogue to match current document copy.")
		return false
	if not String(Dictionary(return_entries[9]).get("text", "")).contains("这是救出她的第一步"):
		printerr("Expected first return dialogue to carry the chapter motivation.")
		return false

	if not service.load_sequence("res://setting/dialogues.tab#missing_dialogue").is_empty():
		printerr("Expected missing dialogue_id to return an empty sequence.")
		return false
	return true
