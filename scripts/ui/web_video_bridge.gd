class_name WebVideoBridge
extends RefCounted

var viewport: Viewport


func setup(p_viewport: Viewport) -> void:
	viewport = p_viewport


func play(
	element_id: String,
	url: String,
	loop: bool,
	muted: bool,
	foreground: bool = false,
	skip_button: bool = false
) -> bool:
	if not OS.has_feature("web") or element_id.is_empty() or url.is_empty():
		return false
	set_canvas_transparent(not foreground)
	_ensure_bridge()
	var script := "window.ProjectEscapeStoryVideo.play(%s, %s, { loop: %s, muted: %s, foreground: %s, skipButton: %s });" % [
		JSON.stringify(element_id),
		JSON.stringify(url),
		_bool_to_js(loop),
		_bool_to_js(muted),
		_bool_to_js(foreground),
		_bool_to_js(skip_button),
	]
	var result = JavaScriptBridge.eval(script, true)
	return result == null or bool(result)


func remove(element_id: String) -> void:
	if not OS.has_feature("web") or element_id.is_empty():
		return
	_ensure_bridge()
	JavaScriptBridge.eval("window.ProjectEscapeStoryVideo.remove(%s);" % JSON.stringify(element_id), false)


func is_ended(element_id: String) -> bool:
	if not OS.has_feature("web") or element_id.is_empty():
		return false
	_ensure_bridge()
	return bool(JavaScriptBridge.eval("window.ProjectEscapeStoryVideo.ended(%s);" % JSON.stringify(element_id), true))


func set_canvas_transparent(enabled: bool) -> void:
	if not OS.has_feature("web"):
		return
	if viewport != null:
		viewport.transparent_bg = enabled
	RenderingServer.set_default_clear_color(Color(0.0, 0.0, 0.0, 0.0) if enabled else Color.BLACK)
	var alpha := "0" if enabled else "1"
	JavaScriptBridge.eval("""
(function() {
	var canvas = document.getElementById('canvas');
	if (!canvas) {
		return;
	}
	canvas.style.background = 'rgba(0,0,0,%s)';
	canvas.style.position = 'relative';
	canvas.style.zIndex = '1';
	document.body.style.backgroundColor = 'black';
	document.documentElement.style.backgroundColor = 'black';
})();
""" % alpha, false)


func res_path_to_web_url(path: String) -> String:
	if path.begins_with("res://"):
		return path.trim_prefix("res://")
	return path


func _ensure_bridge() -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval("""
(function() {
	if (window.ProjectEscapeStoryVideo) {
		return;
	}
	window.ProjectEscapeStoryVideo = {
		play: function(id, src, options) {
			options = options || {};
			var canvas = document.getElementById('canvas');
			var rootId = id + '-root';
			var root = document.getElementById(rootId);
			if (!root) {
				root = document.createElement('div');
				root.id = rootId;
				document.body.appendChild(root);
			}
			root.style.position = 'fixed';
			root.style.left = '0';
			root.style.top = '0';
			root.style.width = '100vw';
			root.style.height = '100vh';
			root.style.zIndex = options.foreground ? '2147483646' : '0';
			root.style.pointerEvents = 'none';
			root.style.backgroundColor = options.foreground ? '#050505' : 'transparent';
			root.style.visibility = 'visible';
			root.style.opacity = '1';
			root.style.display = 'block';
			root.style.transform = 'translateZ(0)';

			var video = document.getElementById(id);
			if (!video) {
				video = document.createElement('video');
				video.id = id;
			}
			if (options.foreground) {
				root.appendChild(video);
			} else if (canvas) {
				document.body.insertBefore(video, canvas);
			} else {
				document.body.appendChild(video);
			}
			video.dataset.projectEscapeEnded = 'false';
			video.src = src;
			video.loop = !!options.loop;
			video.muted = !!options.muted;
			video.autoplay = true;
			video.playsInline = true;
			video.preload = 'auto';
			video.controls = false;
			video.style.position = 'fixed';
			video.style.left = '0';
			video.style.top = '0';
			video.style.width = '100vw';
			video.style.height = '100vh';
			video.style.objectFit = 'cover';
			video.style.zIndex = options.foreground ? '0' : '0';
			video.style.pointerEvents = 'none';
			video.style.backgroundColor = '#050505';
			video.style.visibility = 'visible';
			video.style.opacity = '1';
			video.style.display = 'block';
			video.onended = function() {
				video.dataset.projectEscapeEnded = 'true';
			};
			video.onerror = function() {
				video.dataset.projectEscapeEnded = 'true';
				console.warn('ProjectEscape video failed: ' + src);
			};
			var promise = video.play();
			if (promise && promise.catch) {
				promise.catch(function(error) {
					console.warn('ProjectEscape video play rejected: ' + error);
					if (!options.loop) {
						video.dataset.projectEscapeEnded = 'true';
					}
				});
			}
			var skipId = id + '-skip';
			var skipButton = document.getElementById(skipId);
			if (skipButton) {
				skipButton.remove();
			}
			if (options.skipButton) {
				skipButton = document.createElement('button');
				skipButton.id = skipId;
				skipButton.type = 'button';
				skipButton.textContent = '\u8df3\u8fc7\u5f71\u50cf';
				skipButton.style.position = 'fixed';
				skipButton.style.right = '36px';
				skipButton.style.bottom = '34px';
				skipButton.style.zIndex = '2147483647';
				skipButton.style.pointerEvents = 'auto';
				skipButton.style.padding = '9px 18px';
				skipButton.style.border = '1px solid rgba(233, 216, 158, 0.78)';
				skipButton.style.borderRadius = '2px';
				skipButton.style.background = 'rgba(8, 8, 8, 0.72)';
				skipButton.style.color = '#f1e7bd';
				skipButton.style.font = '16px sans-serif';
				skipButton.style.cursor = 'pointer';
				skipButton.onclick = function() {
					video.dataset.projectEscapeEnded = 'true';
					video.pause();
				};
				document.body.appendChild(skipButton);
			}
			return true;
		},
		remove: function(id) {
			var skipButton = document.getElementById(id + '-skip');
			if (skipButton) {
				skipButton.remove();
			}
			var video = document.getElementById(id);
			if (video) {
				video.pause();
				video.removeAttribute('src');
				video.load();
				video.remove();
			}
			var root = document.getElementById(id + '-root');
			if (root) {
				root.remove();
			}
		},
		ended: function(id) {
			var video = document.getElementById(id);
			return !video || video.dataset.projectEscapeEnded === 'true' || video.ended;
		}
	};
})();
""", false)


func _bool_to_js(value: bool) -> String:
	return "true" if value else "false"
