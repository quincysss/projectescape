extends SceneTree

const OPENING_CINEMATIC_PATH := "res://assets/cinematics/source/opening_intro_cinematic_720p.mp4"
const OPENING_CINEMATIC_FALLBACK_PATH := "res://assets/cinematics/opening_intro_cinematic_720p.ogv"
const MAIN_MENU_BACKGROUND_PATH := "res://assets/cinematics/main_menu/main_menu_background_loop_1080p.mp4"

func _initialize() -> void:
	var ok := _verify_opening_cinematic()
	ok = _verify_main_menu_background() and ok
	print("Cinematic asset verified." if ok else "Cinematic asset check failed.")
	quit(0 if ok else 1)

func _verify_opening_cinematic() -> bool:
	if not _verify_mp4_video_stream(OPENING_CINEMATIC_PATH, "opening cinematic"):
		return false
	if FileAccess.file_exists(OPENING_CINEMATIC_FALLBACK_PATH) and not _verify_ogg_video_stream(OPENING_CINEMATIC_FALLBACK_PATH, "opening cinematic fallback"):
		return false
	return true

func _verify_main_menu_background() -> bool:
	return _verify_mp4_video_stream(MAIN_MENU_BACKGROUND_PATH, "main menu background")

func _verify_mp4_video_stream(path: String, label: String) -> bool:
	if not FileAccess.file_exists(path):
		printerr("Expected %s MP4 file at %s." % [label, path])
		return false
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Expected %s MP4 file to be readable." % label)
		return false
	var header := file.get_buffer(16)
	if not _buffer_has_ascii(header, "ftyp"):
		printerr("Expected %s to be an MP4 container." % label)
		return false
	var stream := ResourceLoader.load(path, "VideoStream")
	if not (stream is VideoStream):
		printerr("Expected %s MP4 to load as VideoStream through the FFmpeg GDExtension." % label)
		return false
	return true

func _verify_ogg_video_stream(path: String, label: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		printerr("Expected %s file to be readable." % label)
		return false
	var header := file.get_buffer(512)
	if not _buffer_starts_with_ascii(header, "OggS"):
		printerr("Expected %s to be an Ogg container." % label)
		return false
	if not _buffer_has_ascii(header, "theora"):
		printerr("Expected %s to use Theora video." % label)
		return false
	if not _buffer_has_ascii(header, "vorbis"):
		printerr("Expected %s to use Vorbis audio." % label)
		return false
	var stream := ResourceLoader.load(path, "VideoStream")
	if not (stream is VideoStream):
		printerr("Expected %s to load as VideoStream." % label)
		return false
	return true

func _buffer_starts_with_ascii(buffer: PackedByteArray, text: String) -> bool:
	var expected := text.to_ascii_buffer()
	if buffer.size() < expected.size():
		return false
	for index in range(expected.size()):
		if buffer[index] != expected[index]:
			return false
	return true

func _buffer_has_ascii(buffer: PackedByteArray, text: String) -> bool:
	var expected := text.to_ascii_buffer()
	if expected.is_empty() or buffer.size() < expected.size():
		return false
	for start in range(buffer.size() - expected.size() + 1):
		var matched := true
		for index in range(expected.size()):
			if buffer[start + index] != expected[index]:
				matched = false
				break
		if matched:
			return true
	return false
