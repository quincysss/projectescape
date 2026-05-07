class_name RunResultBuilder
extends RefCounted

func build_extraction_result(run_director) -> Dictionary:
	var gained: Array[Dictionary] = []
	if run_director != null and run_director.inventory_component != null:
		gained.append_array(run_director.inventory_component.get_items_snapshot())
	if run_director != null and run_director.home_storage_component != null:
		gained.append_array(run_director.home_storage_component.get_items_snapshot())
	return {
		"result_type": "EXTRACTED",
		"message": "撤离成功：带回 %s 组物品。" % gained.size(),
		"warehouse_items": gained,
		"lost_items": [],
		"stats": _build_stats(run_director),
	}

func build_death_result(run_director, reason: String = "stability_depleted") -> Dictionary:
	var kept: Array[Dictionary] = []
	var lost: Array[Dictionary] = []
	if run_director != null and run_director.home_storage_component != null:
		kept.append_array(run_director.home_storage_component.get_items_snapshot())
	if run_director != null and run_director.inventory_component != null:
		lost.append_array(run_director.inventory_component.get_items_snapshot())
	return {
		"result_type": "DEAD",
		"reason": reason,
		"message": "探索失败：稳定值耗尽。家中暂存物品已保留。",
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
		"repaired_outpost_count": run_director.context.repaired_outpost_count,
		"weight_stage": run_director.context.weight_stage,
		"stability_stage": run_director.context.stability_stage,
	}
