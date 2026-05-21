class_name ChapterProgressService
extends RefCounted


func build_chapter_1_snapshot(flags: Dictionary) -> Dictionary:
	var crafted := bool(flags.get("first_sale_good_crafted", false))
	var shelved := bool(flags.get("first_sale_good_shelved", false))
	var settled := bool(flags.get("first_shop_settlement_completed", false))
	var completed := bool(flags.get("chapter_1_completed", false))
	return {
		"chapter_id": "chapter_1",
		"title": "第一章：重启杂货店",
		"subtitle": "完成首次营业",
		"goal_type": "first_shop_tutorial",
		"active": bool(flags.get("chapter_1_goal_active", false)) and not completed,
		"completed": completed,
		"objectives": [
			{
				"objective_id": "craft_first_sale_good",
				"label": "制造第一批可售物资",
				"completed": crafted,
			},
			{
				"objective_id": "shelve_first_sale_good",
				"label": "将可售物资摆上货台",
				"completed": shelved,
			},
			{
				"objective_id": "finish_first_shop_day",
				"label": "完成第一次开店结算",
				"completed": settled,
			},
		],
	}


func contains_sale_good(items: Array) -> bool:
	for item in items:
		if item is Dictionary and is_sale_good_item(item):
			return true
	return false


func is_sale_good_item(item: Dictionary) -> bool:
	if String(item.get("item_type", "")) == "sale_good":
		return true
	var tags = item.get("tags", [])
	if tags is Array:
		return Array(tags).has("sale_good")
	return String(tags).split(";", false).has("sale_good")


func is_first_shop_tutorial_complete(flags: Dictionary) -> bool:
	return (
		bool(flags.get("first_sale_good_crafted", false))
		and bool(flags.get("first_sale_good_shelved", false))
		and bool(flags.get("first_shop_settlement_completed", false))
	)
