class_name HomeSafeZone
extends SafeZone

func _ready() -> void:
	zone_id = &"home"
	zone_type = "home"
	is_active = true
	restore_stability = true
	allow_storage = true
	allow_extraction = true
	super()

func can_show_overview_signals() -> bool:
	return is_active

func can_store_items() -> bool:
	return is_active

func can_extract(extraction_unlocked: bool = false) -> bool:
	return is_active and extraction_unlocked
