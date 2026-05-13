class_name ProjectAudioManager
extends Node

signal bgm_changed(bgm_id: String, path: String, played: bool)
signal sfx_requested(sfx_id: String, path: String, played: bool)
signal loop_sfx_changed(sfx_id: String, active: bool, path: String, played: bool)
signal audio_asset_missing(audio_id: String, path: String)

const MANIFEST_PATH := "res://data/audio/audio_manifest.json"

const BGM_BASE_SAFE_HOUSE := "base_safe_house"
const BGM_RUN_SAFE_HOUSE := "run_safe_house"
const BGM_RUN_EXPLORATION := "run_exploration"

const SFX_STABILITY_CRITICAL_LOOP := "stability_critical_loop"
const SFX_CONTAINER_OPEN_LOOP := "container_open_loop"
const SFX_CONTAINER_OPEN_COMPLETE := "container_open_complete"
const SFX_OUTPOST_REPAIR_COMPLETE := "outpost_repair_complete"
const SFX_EXTRACTION_SUCCESS := "cue_extraction_success"
const SFX_PLAYER_DEATH := "cue_player_death"
const SFX_UI_BUTTON_CLICK := "ui_button_click"
const SFX_UI_ITEM_CLICK := "ui_item_click"

const MUSIC_BUS := "Master"
const SFX_BUS := "Master"

@export var log_missing_assets := false
@export var log_bgm_playback := false

var bgm_player: AudioStreamPlayer
var _manifest: Dictionary = {}
var _current_bgm_id := ""
var _current_bgm_path := ""
var _loop_players: Dictionary = {}
var _missing_assets: Dictionary = {}

func _ready() -> void:
	_ensure_players()
	reload_manifest()

func reload_manifest() -> bool:
	_manifest = _load_manifest()
	return not _manifest.is_empty()

func play_base_safe_house_bgm() -> bool:
	return play_bgm(BGM_BASE_SAFE_HOUSE)

func play_run_safe_house_bgm() -> bool:
	return play_bgm(BGM_RUN_SAFE_HOUSE)

func play_run_exploration_bgm() -> bool:
	return play_bgm(BGM_RUN_EXPLORATION)

func play_bgm(bgm_id: String, force_restart: bool = false) -> bool:
	_ensure_players()
	var config := get_bgm_config(bgm_id)
	var path := String(config.get("path", ""))
	if path.is_empty():
		_stop_bgm_immediate()
		bgm_changed.emit(bgm_id, "", false)
		return false
	if not force_restart and bgm_player.playing and _current_bgm_id == bgm_id:
		return true
	var stream := _load_audio_stream(bgm_id, path)
	_current_bgm_id = bgm_id
	_current_bgm_path = path
	if stream == null:
		_stop_bgm_immediate()
		bgm_changed.emit(bgm_id, path, false)
		return false
	bgm_player.stream = stream
	bgm_player.volume_db = float(config.get("volume_db", -8.0))
	bgm_player.bus = MUSIC_BUS
	bgm_player.play()
	if log_bgm_playback:
		print("[AudioManager] Playing BGM '%s' path=%s bus=%s volume_db=%.1f length=%.2f" % [
			bgm_id,
			path,
			bgm_player.bus,
			bgm_player.volume_db,
			bgm_player.stream.get_length(),
		])
	bgm_changed.emit(bgm_id, path, true)
	return true

func stop_bgm() -> void:
	_stop_bgm_immediate()

func pause_bgm() -> void:
	_ensure_players()
	if bgm_player.stream != null and bgm_player.playing:
		bgm_player.stream_paused = true

func resume_bgm() -> void:
	_ensure_players()
	if bgm_player.stream != null:
		bgm_player.stream_paused = false
		if not bgm_player.playing and not _current_bgm_id.is_empty():
			bgm_player.play()
		return
	if not _current_bgm_id.is_empty():
		play_bgm(_current_bgm_id, true)

func set_stability_critical_loop_active(active: bool) -> void:
	if active:
		start_loop_sfx(SFX_STABILITY_CRITICAL_LOOP)
	else:
		stop_loop_sfx(SFX_STABILITY_CRITICAL_LOOP)

func start_container_open_loop() -> bool:
	return start_loop_sfx(SFX_CONTAINER_OPEN_LOOP)

func stop_container_open_loop() -> void:
	stop_loop_sfx(SFX_CONTAINER_OPEN_LOOP)

func play_container_open_complete() -> bool:
	return play_sfx(SFX_CONTAINER_OPEN_COMPLETE)

func play_outpost_repair_complete() -> bool:
	return play_sfx(SFX_OUTPOST_REPAIR_COMPLETE)

func play_extraction_success_cue() -> bool:
	return play_sfx(SFX_EXTRACTION_SUCCESS)

func play_player_death_cue() -> bool:
	return play_sfx(SFX_PLAYER_DEATH)

func play_ui_button_click() -> bool:
	return play_sfx(SFX_UI_BUTTON_CLICK)

func play_ui_item_click() -> bool:
	return play_sfx(SFX_UI_ITEM_CLICK)

func play_sfx(sfx_id: String) -> bool:
	_ensure_players()
	var config := get_sfx_config(sfx_id)
	var path := String(config.get("path", ""))
	if path.is_empty():
		sfx_requested.emit(sfx_id, "", false)
		return false
	var stream := _load_audio_stream(sfx_id, path)
	if stream == null:
		sfx_requested.emit(sfx_id, path, false)
		return false
	var player := AudioStreamPlayer.new()
	player.name = "OneShot_%s" % _safe_node_suffix(sfx_id)
	player.stream = stream
	player.volume_db = float(config.get("volume_db", -4.0))
	player.bus = SFX_BUS
	add_child(player)
	player.finished.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)
	player.play()
	sfx_requested.emit(sfx_id, path, true)
	return true

func start_loop_sfx(sfx_id: String) -> bool:
	_ensure_players()
	if _loop_players.has(sfx_id):
		var current = _loop_players[sfx_id]
		if is_instance_valid(current):
			if not current.playing:
				current.play()
			return true
		_loop_players.erase(sfx_id)
	var config := get_sfx_config(sfx_id)
	var path := String(config.get("path", ""))
	if path.is_empty():
		loop_sfx_changed.emit(sfx_id, true, "", false)
		return false
	var stream := _load_audio_stream(sfx_id, path)
	if stream == null:
		loop_sfx_changed.emit(sfx_id, true, path, false)
		return false
	var player := AudioStreamPlayer.new()
	player.name = "Loop_%s" % _safe_node_suffix(sfx_id)
	player.stream = stream
	player.volume_db = float(config.get("volume_db", -8.0))
	player.bus = SFX_BUS
	add_child(player)
	_loop_players[sfx_id] = player
	player.finished.connect(func():
		if _loop_players.get(sfx_id) == player and is_instance_valid(player):
			player.play()
	)
	player.play()
	loop_sfx_changed.emit(sfx_id, true, path, true)
	return true

func stop_loop_sfx(sfx_id: String) -> void:
	if not _loop_players.has(sfx_id):
		return
	var player = _loop_players[sfx_id]
	_loop_players.erase(sfx_id)
	if is_instance_valid(player):
		player.stop()
		player.queue_free()
	var config := get_sfx_config(sfx_id)
	loop_sfx_changed.emit(sfx_id, false, String(config.get("path", "")), true)

func stop_all_loops() -> void:
	for sfx_id in _loop_players.keys():
		stop_loop_sfx(String(sfx_id))

func get_bgm_config(bgm_id: String) -> Dictionary:
	return _section_config("bgm", bgm_id)

func get_sfx_config(sfx_id: String) -> Dictionary:
	return _section_config("sfx", sfx_id)

func get_audio_path(section: String, audio_id: String) -> String:
	return String(_section_config(section, audio_id).get("path", ""))

func get_expected_audio_paths() -> PackedStringArray:
	var paths := PackedStringArray()
	for section in ["bgm", "sfx"]:
		var section_data: Dictionary = _manifest.get(section, {})
		for audio_id in section_data.keys():
			var path := String(section_data[audio_id].get("path", ""))
			if not path.is_empty():
				paths.append(path)
	return paths

func _ensure_players() -> void:
	if bgm_player != null and is_instance_valid(bgm_player):
		_connect_bgm_finished()
		return
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BgmPlayer"
	bgm_player.bus = MUSIC_BUS
	add_child(bgm_player)
	_connect_bgm_finished()

func _connect_bgm_finished() -> void:
	if bgm_player == null or not is_instance_valid(bgm_player):
		return
	if not bgm_player.finished.is_connected(_on_bgm_finished):
		bgm_player.finished.connect(_on_bgm_finished)

func _on_bgm_finished() -> void:
	if _current_bgm_id.is_empty():
		return
	if not _should_loop_current_bgm():
		return
	if bgm_player == null or not is_instance_valid(bgm_player) or bgm_player.stream == null:
		return
	bgm_player.play()

func _should_loop_current_bgm() -> bool:
	if _current_bgm_id.is_empty():
		return false
	return bool(get_bgm_config(_current_bgm_id).get("loop", true))

func _load_manifest() -> Dictionary:
	if not FileAccess.file_exists(MANIFEST_PATH):
		return {}
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		return parsed
	return {}

func _section_config(section: String, audio_id: String) -> Dictionary:
	if _manifest.is_empty():
		reload_manifest()
	var section_data: Dictionary = _manifest.get(section, {})
	var config = section_data.get(audio_id, {})
	if config is Dictionary:
		return config
	return {}

func _load_audio_stream(audio_id: String, path: String) -> AudioStream:
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		_note_missing_asset(audio_id, path)
		return null
	var resource := load(path)
	if resource is AudioStream:
		return resource
	_note_missing_asset(audio_id, path)
	return null

func _note_missing_asset(audio_id: String, path: String) -> void:
	var key := "%s:%s" % [audio_id, path]
	if _missing_assets.has(key):
		return
	_missing_assets[key] = true
	if log_missing_assets:
		print("[AudioManager] Missing audio asset '%s' at %s" % [audio_id, path])
	audio_asset_missing.emit(audio_id, path)

func _stop_bgm_immediate() -> void:
	if bgm_player != null and is_instance_valid(bgm_player):
		bgm_player.stop()
		bgm_player.stream = null
	_current_bgm_id = ""
	_current_bgm_path = ""

func _safe_node_suffix(value: String) -> String:
	return value.replace("/", "_").replace(":", "_").replace(".", "_")
