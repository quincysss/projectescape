extends SceneTree

const GameDataRegistryScript := preload("res://scripts/data/game_data_registry.gd")
const SSLootDirectorScript := preload("res://scripts/run/ss_loot_director.gd")

const REPORT_PATH := "res://reports/container_loot_100_openings_ss_active.md"
const OPEN_COUNT := 100
const SS_BUDGET_TOTAL := 2
const BASE_SEED := 2026051201

const CONTAINER_CASES := [
	{"type_id": "cardboard_box", "display_name": "小纸箱", "ring": "middle", "seed_offset": 11},
	{"type_id": "wooden_crate", "display_name": "木箱", "ring": "outer", "seed_offset": 22},
	{"type_id": "tool_cabinet", "display_name": "工具柜", "ring": "far_outer", "seed_offset": 33},
	{"type_id": "medical_cabinet", "display_name": "医疗柜", "ring": "far_outer", "seed_offset": 44},
	{"type_id": "small_safe", "display_name": "小保险箱", "ring": "far_outer", "seed_offset": 55},
	{"type_id": "large_safe", "display_name": "大保险柜", "ring": "far_outer", "seed_offset": 66},
	{"type_id": "anomaly_case", "display_name": "异常箱", "ring": "far_outer", "seed_offset": 77},
]

func _initialize() -> void:
	var ok := _generate_report()
	print("Container loot 100-opening report generated: %s" % REPORT_PATH if ok else "Container loot report generation failed.")
	quit(0 if ok else 1)

func _generate_report() -> bool:
	var registry = GameDataRegistryScript.new()
	if not registry.load_all():
		printerr("Data registry load failed: %s" % str(registry.load_errors))
		return false

	var lines: Array[String] = []
	lines.append("# 容器 100 次开箱掉落报告")
	lines.append("")
	lines.append("- 生成时间：%s" % Time.get_datetime_string_from_system(false, true))
	lines.append("- 使用逻辑：`GameDataRegistry.generate_container_loot()` + `SSLootDirector.try_generate_ss()`")
	lines.append("- 模拟条件：为了观察 SS 产出，本报告按“当前局已触发 SS 池”运行，`ss_budget_total = %d`。实际游戏中仍需先经过每日 SS 判定。"% SS_BUDGET_TOTAL)
	lines.append("- 环带选择：每个容器使用它可出现的最高风险环带或代表环带；小纸箱使用 `middle`，木箱使用 `outer`，其余使用 `far_outer`。")
	lines.append("- 开箱次数：每种容器 %d 次。表格中的品质统计按道具单位计数，不按开箱次数计数。" % OPEN_COUNT)
	lines.append("")

	var all_summaries: Array[Dictionary] = []
	var detail_sections: Array[String] = []
	for case_data in CONTAINER_CASES:
		var summary := _simulate_container(registry, case_data)
		all_summaries.append(summary)
		detail_sections.append_array(_build_detail_section(summary))

	lines.append("## 汇总")
	lines.append("")
	lines.append("| 容器 | 环带 | SS单箱概率配置 | 开箱数 | 总道具数 | 平均道具/箱 | C | B | A | S | SS | SS命中箱数 | SS预算使用 |")
	lines.append("| --- | --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |")
	for summary in all_summaries:
		var quality_counts: Dictionary = summary.get("quality_counts", {})
		lines.append("| %s (`%s`) | `%s` | %s | %d | %d | %.2f | %d | %d | %d | %d | %d | %d | %d/%d |" % [
			String(summary.get("display_name", "")),
			String(summary.get("type_id", "")),
			String(summary.get("ring", "")),
			_percent(float(summary.get("ss_chance", 0.0))),
			int(summary.get("open_count", 0)),
			int(summary.get("total_items", 0)),
			float(summary.get("average_items", 0.0)),
			int(quality_counts.get("C", 0)),
			int(quality_counts.get("B", 0)),
			int(quality_counts.get("A", 0)),
			int(quality_counts.get("S", 0)),
			int(quality_counts.get("SS", 0)),
			int(summary.get("ss_hit_openings", 0)),
			int(summary.get("ss_budget_used", 0)),
			int(summary.get("ss_budget_total", 0)),
		])
	lines.append("")
	lines.append("## 道具数量汇总")
	lines.append("")
	for summary in all_summaries:
		lines.append("### %s (`%s`)" % [String(summary.get("display_name", "")), String(summary.get("type_id", ""))])
		lines.append("")
		lines.append(_item_count_text(Dictionary(summary.get("item_counts", {}))))
		lines.append("")

	lines.append_array(detail_sections)
	return _write_text(REPORT_PATH, "\n".join(lines))

func _simulate_container(registry, case_data: Dictionary) -> Dictionary:
	var type_id := String(case_data.get("type_id", ""))
	var ring := String(case_data.get("ring", "inner"))
	var container_def: Dictionary = registry.get_container_type(type_id)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(BASE_SEED + int(case_data.get("seed_offset", 0)))

	var ss_director = SSLootDirectorScript.new()
	ss_director.setup(registry)
	ss_director.begin_run({"active": true, "budget_total": SS_BUDGET_TOTAL})

	var details: Array[Dictionary] = []
	var quality_counts := {"C": 0, "B": 0, "A": 0, "S": 0, "SS": 0}
	var item_counts := {}
	var ss_hit_openings := 0
	var total_items := 0

	for open_index in range(1, OPEN_COUNT + 1):
		var rewards: Array[Dictionary] = []
		var ss_stack: Dictionary = ss_director.try_generate_ss(container_def, ring, rng)
		if not ss_stack.is_empty():
			rewards.append(ss_stack)
		rewards.append_array(registry.generate_container_loot(container_def, ring, rng))

		var opening_has_ss := false
		for item in rewards:
			var quality := String(item.get("quality", "C"))
			quality_counts[quality] = int(quality_counts.get(quality, 0)) + 1
			if quality == "SS":
				opening_has_ss = true
			var name := _item_label(item)
			item_counts[name] = int(item_counts.get(name, 0)) + 1
			total_items += 1
		if opening_has_ss:
			ss_hit_openings += 1

		var event: Dictionary = ss_director.debug_events.back() if not ss_director.debug_events.is_empty() else {}
		details.append({
			"index": open_index,
			"content": _opening_content_text(rewards),
			"quality_summary": _opening_quality_text(rewards),
			"ss_event": _ss_event_text(registry, event),
		})

	var debug_snapshot: Dictionary = ss_director.get_debug_snapshot()
	return {
		"type_id": type_id,
		"display_name": String(case_data.get("display_name", type_id)),
		"ring": ring,
		"seed": int(BASE_SEED + int(case_data.get("seed_offset", 0))),
		"open_count": OPEN_COUNT,
		"ss_chance": registry.get_ss_container_chance(type_id),
		"ss_budget_total": SS_BUDGET_TOTAL,
		"ss_budget_used": int(debug_snapshot.get("ss_budget_used", 0)),
		"ss_hit_openings": ss_hit_openings,
		"total_items": total_items,
		"average_items": float(total_items) / float(OPEN_COUNT),
		"quality_counts": quality_counts,
		"item_counts": item_counts,
		"details": details,
	}

func _build_detail_section(summary: Dictionary) -> Array[String]:
	var lines: Array[String] = []
	lines.append("## %s (`%s`) 100 次明细" % [String(summary.get("display_name", "")), String(summary.get("type_id", ""))])
	lines.append("")
	lines.append("- 环带：`%s`" % String(summary.get("ring", "")))
	lines.append("- 随机种子：`%d`" % int(summary.get("seed", 0)))
	lines.append("- 条件 SS 单箱概率：%s；SS 预算使用：%d/%d" % [
		_percent(float(summary.get("ss_chance", 0.0))),
		int(summary.get("ss_budget_used", 0)),
		int(summary.get("ss_budget_total", 0)),
	])
	lines.append("")
	lines.append("| # | 开出内容 | 品质统计 | SS事件 |")
	lines.append("| ---: | --- | --- | --- |")
	for detail in Array(summary.get("details", [])):
		lines.append("| %d | %s | %s | %s |" % [
			int(detail.get("index", 0)),
			_escape_cell(String(detail.get("content", ""))),
			_escape_cell(String(detail.get("quality_summary", ""))),
			_escape_cell(String(detail.get("ss_event", ""))),
		])
	lines.append("")
	return lines

func _opening_content_text(rewards: Array[Dictionary]) -> String:
	if rewards.is_empty():
		return "无"
	var counts := {}
	for item in rewards:
		var label := _item_label(item)
		counts[label] = int(counts.get(label, 0)) + 1
	var parts: Array[String] = []
	for label in counts.keys():
		parts.append("%s x%d" % [String(label), int(counts[label])])
	parts.sort()
	return "；".join(parts)

func _opening_quality_text(rewards: Array[Dictionary]) -> String:
	if rewards.is_empty():
		return "-"
	var counts := {"C": 0, "B": 0, "A": 0, "S": 0, "SS": 0}
	for item in rewards:
		var quality := String(item.get("quality", "C"))
		counts[quality] = int(counts.get(quality, 0)) + 1
	var parts: Array[String] = []
	for quality in ["C", "B", "A", "S", "SS"]:
		var count := int(counts.get(quality, 0))
		if count > 0:
			parts.append("%s:%d" % [quality, count])
	return "，".join(parts)

func _item_label(item: Dictionary) -> String:
	return "%s(%s)" % [
		String(item.get("display_name", item.get("item_id", ""))),
		String(item.get("quality", "C")),
	]

func _item_count_text(item_counts: Dictionary) -> String:
	if item_counts.is_empty():
		return "无"
	var parts: Array[String] = []
	for label in item_counts.keys():
		parts.append("- %s：%d" % [String(label), int(item_counts[label])])
	parts.sort()
	return "\n".join(parts)

func _ss_event_text(registry, event: Dictionary) -> String:
	if event.is_empty():
		return "-"
	var event_name := String(event.get("event", ""))
	match event_name:
		"hit":
			var item_id := String(event.get("item_id", ""))
			var item: Dictionary = registry.get_item(item_id)
			var item_name := String(item.get("name", item_id))
			return "SS命中%s：%s" % ["（保底）" if bool(event.get("forced", false)) else "", item_name]
		"miss":
			return "SS未中（roll %.4f / %s）" % [float(event.get("roll_value", 0.0)), _percent(float(event.get("chance", 0.0)))]
		"budget_exhausted":
			return "SS预算已耗尽"
		"inactive":
			return "SS局未激活"
		"pool_empty":
			return "SS池为空"
		_:
			return event_name

func _percent(value: float) -> String:
	return "%.3f%%" % (value * 100.0)

func _escape_cell(value: String) -> String:
	return value.replace("|", "\\|").replace("\n", "<br>")

func _write_text(path: String, text: String) -> bool:
	var absolute_dir := ProjectSettings.globalize_path(path.get_base_dir())
	var dir_result := DirAccess.make_dir_recursive_absolute(absolute_dir)
	if dir_result != OK:
		printerr("Failed to create report directory: %s" % absolute_dir)
		return false
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("Failed to open report path: %s" % path)
		return false
	file.store_string(text)
	file.close()
	return true
