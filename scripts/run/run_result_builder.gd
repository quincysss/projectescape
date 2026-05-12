class_name RunResultBuilder
extends RefCounted

func build_extraction_result(run_director) -> Dictionary:
	var gained: Array[Dictionary] = []
	if run_director != null and run_director.inventory_component != null:
		gained.append_array(_tag_items(run_director.inventory_component.get_items_snapshot(), "背包", "已带回"))
	if run_director != null and run_director.home_storage_component != null:
		gained.append_array(_tag_items(run_director.home_storage_component.get_items_snapshot(), "安全屋", "已带回"))
	if run_director != null and run_director.has_method("get_all_outpost_storage_items_snapshot"):
		gained.append_array(_tag_items(run_director.get_all_outpost_storage_items_snapshot(), "前哨站", "已带回"))
	return {
		"result_type": "EXTRACTED",
		"message": "撤离成功：带回 %s 组物品。" % gained.size(),
		"warehouse_items": gained,
		"lost_items": [],
		"stats": _build_stats(run_director),
	}

func build_death_result(run_director, reason: String = "stability_depleted") -> Dictionary:
	return _build_failure_result(
		run_director,
		"DEAD",
		reason,
		"探索失败：稳定值耗尽。家中暂存物品已保留。"
	)

func build_timeout_result(run_director, reason: String = "time_expired") -> Dictionary:
	return _build_failure_result(
		run_director,
		"TIMEOUT_FAILED",
		reason,
		"探索失败：对局时间耗尽。家中暂存物品已保留。"
	)

func _build_failure_result(run_director, result_type: String, reason: String, message: String) -> Dictionary:
	var kept: Array[Dictionary] = []
	var lost: Array[Dictionary] = []
	if run_director != null and run_director.home_storage_component != null:
		kept.append_array(_tag_items(run_director.home_storage_component.get_items_snapshot(), "安全屋", "已保留"))
	if run_director != null and run_director.inventory_component != null:
		lost.append_array(_tag_items(run_director.inventory_component.get_items_snapshot(), "背包", "已遗失"))
	if run_director != null and run_director.has_method("get_all_outpost_storage_items_snapshot"):
		lost.append_array(_tag_items(run_director.get_all_outpost_storage_items_snapshot(), "前哨站", "已遗失"))
	return {
		"result_type": result_type,
		"reason": reason,
		"message": message,
		"warehouse_items": kept,
		"lost_items": lost,
		"stats": _build_stats(run_director),
	}

func _build_stats(run_director) -> Dictionary:
	if run_director == null or run_director.context == null:
		return {}
	return {
		"run_id": run_director.context.run_id,
		"elapsed_seconds": run_director.context.elapsed_seconds,
		"remaining_seconds": run_director.context.remaining_seconds,
		"repaired_outpost_count": run_director.context.repaired_outpost_count,
		"weight_stage": run_director.context.weight_stage,
		"stability_stage": run_director.context.stability_stage,
	}

func _tag_items(items: Array, source_text: String, status_text: String) -> Array[Dictionary]:
	var tagged: Array[Dictionary] = []
	for item in items:
		if not (item is Dictionary):
			continue
		var copy: Dictionary = item.duplicate(true)
		copy["settlement_source"] = source_text
		copy["settlement_status"] = status_text
		tagged.append(copy)
	return tagged
