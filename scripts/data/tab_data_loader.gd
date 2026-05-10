class_name TabDataLoader
extends RefCounted

var last_error: String = ""

func load_tab(path: String) -> Array[Dictionary]:
	last_error = ""
	if not FileAccess.file_exists(path):
		last_error = "missing_file:%s" % path
		return []
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		last_error = "open_failed:%s" % path
		return []

	var headers: PackedStringArray = []
	var rows: Array[Dictionary] = []
	var line_number := 0
	while not file.eof_reached():
		var line := file.get_line()
		line_number += 1
		if line.strip_edges().is_empty() or line.begins_with("#"):
			continue
		var cells := line.split("\t", false)
		if headers.is_empty():
			headers = cells
			continue
		var row: Dictionary = {}
		for index in range(headers.size()):
			var value := ""
			if index < cells.size():
				value = cells[index].strip_edges()
			row[String(headers[index])] = value
		row["_source_path"] = path
		row["_line"] = line_number
		rows.append(row)
	return rows

static func split_list(value: String) -> Array[String]:
	var result: Array[String] = []
	for part in value.split(";", false):
		var trimmed := part.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result

static func parse_bool(value: String, default_value: bool = false) -> bool:
	var lower := value.strip_edges().to_lower()
	if lower == "true" or lower == "1" or lower == "yes":
		return true
	if lower == "false" or lower == "0" or lower == "no":
		return false
	return default_value

static func parse_color(value: String, default_value: Color = Color.WHITE) -> Color:
	if value.strip_edges().is_empty():
		return default_value
	return Color(value)
