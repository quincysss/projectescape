class_name OutpostCandidatePoint
extends Marker2D

@export_enum("first", "second") var outpost_tier: String = "first"
@export var candidate_id: String = ""

func _ready() -> void:
	add_to_group("outpost_candidate_points")
	if outpost_tier == "first":
		add_to_group("first_outpost_candidates")
	else:
		add_to_group("second_outpost_candidates")

func get_candidate_id() -> String:
	if not candidate_id.is_empty():
		return candidate_id
	return name
