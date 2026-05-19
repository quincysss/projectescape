class_name RunInventoryPanelController
extends RefCounted

const STORAGE_SOURCE_ID := "storage"

var selected_inventory_index: int = -1
var home_storage_user_closed: bool = false
var active_outpost_storage_id: String = ""

func on_inventory_item_clicked(meta: Variant, run_director) -> Dictionary:
	var index := item_meta_index(meta, "inventory")
	if index < 0:
		return _result(false, "", false)
	return select_inventory_item_at(index, run_director)

func on_storage_item_clicked(meta: Variant, run_director, inventory_panel_visible: bool = true) -> Dictionary:
	var index := item_meta_index(meta, STORAGE_SOURCE_ID)
	if index < 0:
		index = item_meta_index(meta, "home")
	if index < 0:
		return _result(false, "", false)
	if has_selected_inventory_item(run_director):
		return deposit_inventory_item_at(index, run_director, selected_inventory_index, inventory_panel_visible)
	return withdraw_active_storage_item_at(index, run_director)

func deposit_inventory_item_at(index: int, run_director, inventory_index: int = -1, inventory_panel_visible: bool = true) -> Dictionary:
	var result: Dictionary
	var storage_name := active_storage_display_name(run_director)
	var source_inventory_index := inventory_index if inventory_index >= 0 else index
	var target_storage_index := index if inventory_index >= 0 else -1
	if is_active_outpost_storage(run_director):
		result = run_director.deposit_inventory_item_to_outpost(active_outpost_storage_id, source_inventory_index, target_storage_index)
	else:
		result = run_director.deposit_inventory_item_to_home_by_selection(source_inventory_index, target_storage_index)
	if bool(result.get("accepted", false)):
		if selected_inventory_index == source_inventory_index:
			selected_inventory_index = -1
		var item: Dictionary = result.get("item", {})
		return _result(true, "已存入%s：%s" % [storage_name, item.get("display_name", item.get("item_id", ""))])
	sync_inventory_selection_state(inventory_panel_visible, run_director)
	return _result(false, selection_transfer_reason_text(str(result.get("reason", "")), run_director))

func select_inventory_item_at(index: int, run_director) -> Dictionary:
	if run_director == null or run_director.inventory_component == null:
		selected_inventory_index = -1
		return _result(false, "背包不可用。")
	if index < 0 or index >= run_director.inventory_component.items.size():
		selected_inventory_index = -1
		return _result(false, "道具不可用。")
	selected_inventory_index = index
	var item: Dictionary = run_director.inventory_component.items[index]
	return _result(true, "已选中：%s" % item.get("display_name", item.get("item_id", "")))

func discard_selected_inventory_item(run_director, inventory_panel_visible: bool = true) -> Dictionary:
	if not has_selected_inventory_item(run_director):
		return _result(false, "请先选择背包道具。")
	var result: Dictionary = run_director.discard_inventory_item_at(selected_inventory_index)
	if bool(result.get("accepted", false)):
		selected_inventory_index = -1
		var item: Dictionary = result.get("item", {})
		return _result(true, "已丢弃：%s" % item.get("display_name", item.get("item_id", "")))
	sync_inventory_selection_state(inventory_panel_visible, run_director)
	return _result(false, inventory_discard_reason_text(str(result.get("reason", ""))))

func withdraw_active_storage_item_at(index: int, run_director) -> Dictionary:
	var result: Dictionary
	if is_active_outpost_storage(run_director):
		result = run_director.withdraw_outpost_storage_item_to_inventory(active_outpost_storage_id, index)
	else:
		result = run_director.withdraw_home_storage_item_to_inventory(index)
	if bool(result.get("accepted", false)):
		var item: Dictionary = result.get("item", {})
		return _result(true, "已放入背包：%s" % item.get("display_name", item.get("item_id", "")))
	return _result(false, selection_transfer_reason_text(str(result.get("reason", "")), run_director))

func deposit_all(run_director, inventory_panel_visible: bool = true) -> Dictionary:
	if not is_storage_zone_active(run_director):
		return _result(false, "请进入家中或已修复前哨站存放物品。", false, "not_storage_zone")
	if has_selected_inventory_item(run_director):
		return deposit_inventory_item_at(selected_inventory_index, run_director, -1, inventory_panel_visible)
	var index := 0
	while run_director != null and run_director.inventory_component != null and index < run_director.inventory_component.items.size():
		var moved := false
		if is_active_outpost_storage(run_director):
			moved = bool(run_director.deposit_inventory_item_to_outpost(active_outpost_storage_id, index).get("accepted", false))
		else:
			moved = run_director.deposit_inventory_item_to_home(index)
		if not moved:
			index += 1
	sync_inventory_selection_state(inventory_panel_visible, run_director)
	return _result(true, "")

func has_selected_inventory_item(run_director) -> bool:
	return not selected_inventory_item(run_director).is_empty()

func selected_inventory_item_summary(run_director) -> String:
	var item := selected_inventory_item(run_director)
	if item.is_empty():
		return ""
	return "已选：%s" % item.get("display_name", item.get("item_id", ""))

func selected_inventory_item(run_director) -> Dictionary:
	if run_director == null or run_director.inventory_component == null:
		return {}
	if selected_inventory_index < 0 or selected_inventory_index >= run_director.inventory_component.items.size():
		return {}
	return run_director.inventory_component.items[selected_inventory_index]

func sync_inventory_selection_state(inventory_panel_visible: bool, run_director) -> void:
	if selected_inventory_index < 0:
		return
	if not inventory_panel_visible or selected_inventory_item(run_director).is_empty():
		selected_inventory_index = -1

func item_meta_index(meta: Variant, expected_source: String) -> int:
	var parts := String(meta).split(":")
	if parts.size() != 2 or parts[0] != expected_source:
		return -1
	return int(parts[1])

func inventory_discard_reason_text(reason: String) -> String:
	match reason:
		"missing_inventory":
			return "背包不可用。"
		"invalid_item":
			return "道具不可用。"
		_:
			return "无法丢弃该道具。"

func selection_transfer_reason_text(reason: String, run_director) -> String:
	match reason:
		"not_home":
			return "请回到家中整理物品。"
		"not_outpost":
			return "请进入已修复前哨站整理物品。"
		"outpost_inactive":
			return "前哨站尚未修复，无法存储。"
		"outpost_storage_locked":
			return "前哨站安全箱尚未研究。"
		"storage_rejected":
			return "%s空间不足。" % active_storage_display_name(run_director)
		"inventory_rejected":
			return "背包空间或负重不足。"
		"invalid_item":
			return "道具不可用。"
		_:
			return "无法移动该道具。"

func enter_repaired_outpost_safe_zone(station, run_director) -> Dictionary:
	if station == null or not is_instance_valid(station) or run_director == null or run_director.context == null:
		return _result(false, "", false)
	if run_director.context.active_safe_zone_id == station.interact_id:
		return _result(false, "", false)
	run_director.on_safe_zone_entered(station.interact_id)
	if run_director.get_outpost_storage_capacity(station.interact_id) > 0:
		run_director.ensure_outpost_storage(station.interact_id)
		active_outpost_storage_id = station.interact_id
		home_storage_user_closed = false
		return _result(true, "前哨站安全区：稳定值正在恢复，安全箱已开启。")
	active_outpost_storage_id = ""
	return _result(true, "前哨站安全区：稳定值正在恢复，安全箱尚未研究。")

func exit_repaired_outpost_safe_zone(station, run_director) -> Dictionary:
	if station == null or not is_instance_valid(station) or run_director == null or run_director.context == null:
		return _result(false, "", false)
	if run_director.context.active_safe_zone_id != station.interact_id:
		return _result(false, "", false)
	run_director.on_safe_zone_exited(station.interact_id)
	return _result(true, "")

func close_outpost_storage_ui(outpost_id: String, home_storage_panel: Panel, loot_panel: Panel, inventory_panel: Panel) -> void:
	if active_outpost_storage_id != outpost_id:
		return
	active_outpost_storage_id = ""
	home_storage_user_closed = false
	if home_storage_panel != null:
		home_storage_panel.visible = false
	if loot_panel != null and inventory_panel != null and not loot_panel.visible:
		inventory_panel.visible = false

func is_storage_zone_active(run_director) -> bool:
	return (
		run_director != null
		and run_director.context != null
		and (
			run_director.context.active_safe_zone_id == "home"
			or is_active_outpost_storage(run_director)
		)
	)

func is_home_storage_active(run_director) -> bool:
	return run_director != null and run_director.context != null and run_director.context.active_safe_zone_id == "home"

func is_active_outpost_storage(run_director) -> bool:
	return (
		not active_outpost_storage_id.is_empty()
		and run_director != null
		and run_director.context != null
		and run_director.context.active_safe_zone_id == active_outpost_storage_id
		and run_director.context.active_safe_zone_type == "outpost"
	)

func get_active_storage_items_snapshot(run_director) -> Array:
	if is_active_outpost_storage(run_director):
		return run_director.get_outpost_storage_slots_snapshot(active_outpost_storage_id)
	if run_director != null and run_director.home_storage_component != null:
		return run_director.home_storage_component.get_slots_snapshot()
	return []

func get_active_storage_source_id() -> String:
	return STORAGE_SOURCE_ID

func get_active_storage_title(run_director) -> String:
	if is_active_outpost_storage(run_director):
		return "前哨存储"
	return "家中存储"

func active_storage_display_name(run_director) -> String:
	return "前哨" if is_active_outpost_storage(run_director) else "家中"

func get_active_storage_capacity(run_director) -> int:
	if is_active_outpost_storage(run_director):
		return run_director.get_outpost_storage_capacity(active_outpost_storage_id)
	if run_director != null and run_director.home_storage_component != null:
		return run_director.home_storage_component.max_slots
	return 0

func _result(accepted: bool, message: String, refresh: bool = true, reason: String = "") -> Dictionary:
	return {
		"accepted": accepted,
		"message": message,
		"refresh": refresh,
		"reason": reason,
	}
