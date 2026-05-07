class_name OutpostRepairController
extends RefCounted

var run_director
var repaired_outposts: Dictionary = {}

func setup(director, repaired_store: Dictionary) -> void:
	run_director = director
	repaired_outposts = repaired_store

func can_repair(station) -> Dictionary:
	if station == null or not is_instance_valid(station):
		return {"accepted": false, "message": "未找到前哨站。"}
	if station.payload.get("repaired", false):
		return {"accepted": false, "message": "前哨站已经修复。"}
	var requirements: Dictionary = station.payload.get("requirements", {})
	if not has_requirements(requirements):
		return {"accepted": false, "message": "缺少材料：%s" % missing_requirements_text(requirements)}
	return {"accepted": true, "message": ""}

func repair(station) -> Dictionary:
	var validation: Dictionary = can_repair(station)
	if not validation.accepted:
		return validation
	var requirements: Dictionary = station.payload.get("requirements", {})
	run_director.on_outpost_repair_started(station.interact_id)
	for item_id in requirements.keys():
		run_director.inventory_component.remove_item(StringName(item_id), int(requirements[item_id].amount))
	station.payload.repaired = true
	station.payload.repair_state = "ACTIVE"
	repaired_outposts[station.interact_id] = true
	station.modulate = Color(0.3, 1.0, 0.5)
	run_director.on_outpost_repaired(station.interact_id)
	return {"accepted": true, "message": "前哨站修复完成。", "outpost_id": station.interact_id}

func mark_repairing(station) -> void:
	if station == null or not is_instance_valid(station):
		return
	station.payload.repair_state = "REPAIRING"
	station.modulate = Color(1.0, 0.86, 0.35)

func cancel_repairing(station) -> void:
	if station == null or not is_instance_valid(station):
		return
	if station.payload.get("repaired", false):
		return
	station.payload.repair_state = "REPAIRABLE" if can_repair(station).accepted else "UNREPAIRED"
	station.modulate = Color.WHITE

func has_requirements(requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if inventory_count(str(item_id)) < int(requirements[item_id].amount):
			return false
	return true

func missing_requirements_text(requirements: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in requirements.keys():
		var need := int(requirements[item_id].amount)
		var have := inventory_count(str(item_id))
		if have < need:
			parts.append("%s %s/%s" % [requirements[item_id].display_name, have, need])
	return ", ".join(parts)

func inventory_count(item_id: String) -> int:
	if run_director == null or run_director.inventory_component == null:
		return 0
	var count := 0
	for stack in run_director.inventory_component.items:
		if str(stack.item_id) == item_id:
			count += int(stack.amount)
	return count
