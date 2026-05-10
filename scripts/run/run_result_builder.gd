class_name RunResultBuilder
extends RefCounted

func build_extraction_result(run_director) -> Dictionary:
	var gained: Array[Dictionary] = []
	if run_director != null and run_director.inventory_component != null:
		gained.append_array(run_director.inventory_component.get_items_snapshot())
	if run_director != null and run_director.home_storage_component != null:
		gained.append_array(run_director.home_storage_component.get_items_snapshot())
	if run_director != null and run_director.has_method("get_all_outpost_storage_items_snapshot"):
		gained.append_array(run_director.get_all_outpost_storage_items_snapshot())
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
		kept.append_array(run_director.home_storage_component.get_items_snapshot())
	if run_director != null and run_director.inventory_component != null:
		lost.append_array(run_director.inventory_component.get_items_snapshot())
	if run_director != null and run_director.has_method("get_all_outpost_storage_items_snapshot"):
		lost.append_array(run_director.get_all_outpost_storage_items_snapshot())
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
