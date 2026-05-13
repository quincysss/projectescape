class_name FullscreenBackgroundBuilder
extends RefCounted


static func add_image_background(
	parent: Control,
	texture_path: String,
	node_name: String,
	fallback_color: Color,
	dim_color: Color = Color(0.0, 0.0, 0.0, 0.0)
) -> Control:
	var root := Control.new()
	root.name = node_name
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.anchor_right = 1.0
	root.anchor_bottom = 1.0
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	parent.move_child(root, 0)

	var fallback := ColorRect.new()
	fallback.name = "%sFallback" % node_name
	fallback.color = fallback_color
	fallback.set_anchors_preset(Control.PRESET_FULL_RECT)
	fallback.anchor_right = 1.0
	fallback.anchor_bottom = 1.0
	fallback.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(fallback)

	var texture := _load_texture(texture_path)
	if texture != null:
		var image := TextureRect.new()
		image.name = "%sImage" % node_name
		image.set_meta("source_texture_path", texture_path)
		image.texture = texture
		image.set_anchors_preset(Control.PRESET_FULL_RECT)
		image.anchor_right = 1.0
		image.anchor_bottom = 1.0
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(image)

	if dim_color.a > 0.0:
		var dim := ColorRect.new()
		dim.name = "%sDim" % node_name
		dim.color = dim_color
		dim.set_anchors_preset(Control.PRESET_FULL_RECT)
		dim.anchor_right = 1.0
		dim.anchor_bottom = 1.0
		dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(dim)

	return root

static func _load_texture(texture_path: String) -> Texture2D:
	var loaded := ResourceLoader.load(texture_path, "Texture2D", ResourceLoader.CACHE_MODE_REUSE) as Texture2D
	if loaded != null:
		return loaded

	var image := Image.new()
	if image.load(texture_path) == OK:
		return ImageTexture.create_from_image(image)
	return null
