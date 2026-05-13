extends Node

const CLICK_SFX_META := "ui_click_sfx"
const CLICK_SFX_DISABLED_META := "ui_click_sfx_disabled"
const CONNECTED_META := "ui_click_sfx_connected"
const DEFAULT_BUTTON_SFX := "ui_button_click"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_connect_existing_buttons(get_tree().root)
	if not get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.connect(_on_node_added)

func _connect_existing_buttons(root_node: Node) -> void:
	if root_node == null:
		return
	_on_node_added(root_node)
	for child in root_node.get_children():
		_connect_existing_buttons(child)

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_connect_button(node as BaseButton)

func _connect_button(button: BaseButton) -> void:
	if button == null or bool(button.get_meta(CONNECTED_META, false)):
		return
	button.set_meta(CONNECTED_META, true)
	button.pressed.connect(_on_button_pressed.bind(button))

func _on_button_pressed(button: BaseButton) -> void:
	if button == null or not is_instance_valid(button):
		return
	if bool(button.get_meta(CLICK_SFX_DISABLED_META, false)):
		return
	var sfx_id := String(button.get_meta(CLICK_SFX_META, DEFAULT_BUTTON_SFX))
	if sfx_id.is_empty():
		return
	var audio_manager := get_node_or_null("/root/AudioManager")
	if audio_manager != null and audio_manager.has_method("play_sfx"):
		audio_manager.play_sfx(sfx_id)
