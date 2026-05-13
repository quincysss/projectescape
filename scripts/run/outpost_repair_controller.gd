class_name OutpostRepairController
extends RefCounted

const STATE_UNREPAIRED := "UNREPAIRED"
const STATE_PARTIAL_DELIVERED := "PARTIAL_DELIVERED"
const STATE_REPAIRABLE := "REPAIRABLE"
const STATE_REPAIRING := "REPAIRING"
const STATE_ACTIVE := "ACTIVE"

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
	if requirements.is_empty():
		return {"accepted": false, "message": "前哨站缺少修复需求配置。"}
	var delivered: Dictionary = _ensure_delivered_materials(station)
	var submittable: Dictionary = _get_submittable_materials(requirements, delivered)
	if submittable.is_empty():
		_refresh_pending_state(station)
		return {"accepted": false, "message": "缺少材料：%s" % missing_requirements_text_for_station(station)}
	station.payload.repair_state = STATE_REPAIRABLE
	return {"accepted": true, "message": "", "submit": submittable, "progress": repair_progress(station)}

func repair(station) -> Dictionary:
	var validation: Dictionary = can_repair(station)
	if not validation.accepted:
		return validation
	var requirements: Dictionary = station.payload.get("requirements", {})
	var delivered: Dictionary = _ensure_delivered_materials(station)
	var submittable: Dictionary = validation.get("submit", _get_submittable_materials(requirements, delivered))
	var submitted: Dictionary = {}
	for item_id in submittable.keys():
		var requested := int(submittable[item_id])
		var removed: int = _remove_repair_material(String(item_id), requested)
		if removed <= 0:
			continue
		delivered[item_id] = int(delivered.get(item_id, 0)) + removed
		submitted[item_id] = removed
	station.payload.delivered_materials = delivered
	var progress := repair_progress(station)
	if _requirements_fulfilled(requirements, delivered):
		station.payload.repaired = true
		station.payload.repair_state = STATE_ACTIVE
		repaired_outposts[station.interact_id] = true
		station.modulate = Color.WHITE
		run_director.on_outpost_repaired(station.interact_id)
		return {
			"accepted": true,
			"activated": true,
			"message": "前哨站修复完成。",
			"outpost_id": station.interact_id,
			"submitted": submitted,
			"progress": progress,
		}
	station.payload.repaired = false
	station.payload.repair_state = STATE_PARTIAL_DELIVERED
	station.modulate = Color.WHITE
	return {
		"accepted": true,
		"activated": false,
		"message": "已提交材料：进度 %d%%。" % int(round(progress * 100.0)),
		"outpost_id": station.interact_id,
		"submitted": submitted,
		"progress": progress,
	}

func mark_repairing(station) -> void:
	if station == null or not is_instance_valid(station):
		return
	station.payload.repair_state = STATE_REPAIRING
	station.modulate = Color.WHITE
	if run_director != null:
		run_director.on_outpost_repair_started(station.interact_id)

func cancel_repairing(station) -> void:
	if station == null or not is_instance_valid(station):
		return
	if station.payload.get("repaired", false):
		return
	_refresh_pending_state(station)
	station.modulate = Color.WHITE

func has_requirements(requirements: Dictionary) -> bool:
	for item_id in requirements.keys():
		if inventory_count(str(item_id)) < int(requirements[item_id].get("amount", 0)):
			return false
	return true

func missing_requirements_text(requirements: Dictionary) -> String:
	var parts: Array[String] = []
	for item_id in requirements.keys():
		var data: Dictionary = requirements[item_id]
		var need := int(data.get("amount", 0))
		var have := inventory_count(str(item_id))
		if have < need:
			parts.append("%s %s/%s" % [data.get("display_name", item_id), have, need])
	return ", ".join(parts)

func inventory_count(item_id: String) -> int:
	if run_director == null or run_director.inventory_component == null:
		return 0
	var count := 0
	for stack in _repair_material_items():
		if _repair_material_id(stack) == item_id:
			count += int(stack.amount)
	return count

func repair_progress(station) -> float:
	if station == null or not is_instance_valid(station):
		return 0.0
	var requirements: Dictionary = station.payload.get("requirements", {})
	var delivered: Dictionary = _ensure_delivered_materials(station)
	var total_required := 0
	var total_delivered := 0
	for item_id in requirements.keys():
		var required := int(requirements[item_id].get("amount", 0))
		total_required += required
		total_delivered += mini(int(delivered.get(str(item_id), 0)), required)
	if total_required <= 0:
		return 0.0
	return clampf(float(total_delivered) / float(total_required), 0.0, 1.0)

func missing_requirements_text_for_station(station) -> String:
	if station == null or not is_instance_valid(station):
		return ""
	var requirements: Dictionary = station.payload.get("requirements", {})
	var delivered: Dictionary = _ensure_delivered_materials(station)
	var parts: Array[String] = []
	for item_id in requirements.keys():
		var data: Dictionary = requirements[item_id]
		var need := int(data.get("amount", 0))
		var submitted := int(delivered.get(str(item_id), 0))
		var carried := inventory_count(str(item_id))
		var covered := mini(need, submitted + carried)
		if covered < need:
			parts.append("%s %s/%s" % [data.get("display_name", item_id), covered, need])
	return ", ".join(parts)

func _ensure_delivered_materials(station) -> Dictionary:
	var delivered: Dictionary = station.payload.get("delivered_materials", {})
	if delivered == null:
		delivered = {}
	for item_id in station.payload.get("requirements", {}).keys():
		if not delivered.has(str(item_id)):
			delivered[str(item_id)] = 0
	station.payload.delivered_materials = delivered
	return delivered

func _get_submittable_materials(requirements: Dictionary, delivered: Dictionary) -> Dictionary:
	var submittable := {}
	for item_id in requirements.keys():
		var item_key := str(item_id)
		var required := int(requirements[item_id].get("amount", 0))
		var already_delivered := int(delivered.get(item_key, 0))
		var remaining := maxi(0, required - already_delivered)
		if remaining <= 0:
			continue
		var carried := inventory_count(item_key)
		var submit_count := mini(remaining, carried)
		if submit_count > 0:
			submittable[item_key] = submit_count
	return submittable

func _requirements_fulfilled(requirements: Dictionary, delivered: Dictionary) -> bool:
	for item_id in requirements.keys():
		var item_key := str(item_id)
		if int(delivered.get(item_key, 0)) < int(requirements[item_id].get("amount", 0)):
			return false
	return true

func _remove_repair_material(item_id: String, amount: int) -> int:
	if run_director == null or run_director.inventory_component == null:
		return 0
	if run_director.inventory_component.has_method("remove_repair_material"):
		return int(run_director.inventory_component.remove_repair_material(StringName(item_id), amount))
	var remaining := amount
	var removed := 0
	for index in range(run_director.inventory_component.items.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var stack: Dictionary = run_director.inventory_component.items[index]
		if _repair_material_id(stack) != item_id:
			continue
		if not _is_repair_material_stack(stack):
			continue
		var removed_stack: Dictionary = run_director.inventory_component.remove_item_at(index, remaining)
		var moved := int(removed_stack.get("amount", 0))
		remaining -= moved
		removed += moved
	return removed

func _repair_material_items() -> Array:
	if run_director == null or run_director.inventory_component == null:
		return []
	if run_director.inventory_component.has_method("get_repair_material_items_snapshot"):
		return run_director.inventory_component.get_repair_material_items_snapshot()
	if run_director.inventory_component.has_method("get_material_items_snapshot"):
		return run_director.inventory_component.get_material_items_snapshot()
	return run_director.inventory_component.items

func _is_repair_material_stack(stack: Dictionary) -> bool:
	return not _repair_material_id(stack).is_empty()

func _repair_material_id(stack: Dictionary) -> String:
	return String(stack.get("repair_material_id", ""))

func _refresh_pending_state(station) -> void:
	var progress := repair_progress(station)
	var requirements: Dictionary = station.payload.get("requirements", {})
	var delivered: Dictionary = _ensure_delivered_materials(station)
	if _requirements_fulfilled(requirements, delivered):
		station.payload.repair_state = STATE_REPAIRABLE
	elif progress > 0.0:
		station.payload.repair_state = STATE_PARTIAL_DELIVERED
	else:
		station.payload.repair_state = STATE_UNREPAIRED
