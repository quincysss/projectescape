class_name RunSimulationPauseService
extends RefCounted

signal pause_changed(paused: bool, reason: String)

var _tokens: Dictionary = {}


func acquire(token: String) -> void:
	if token.is_empty():
		return
	var was_paused := is_paused()
	_tokens[token] = true
	if not was_paused:
		pause_changed.emit(true, token)


func release(token: String) -> void:
	if token.is_empty() or not _tokens.has(token):
		return
	_tokens.erase(token)
	if _tokens.is_empty():
		pause_changed.emit(false, token)


func clear() -> void:
	var was_paused := is_paused()
	_tokens.clear()
	if was_paused:
		pause_changed.emit(false, "")


func is_paused() -> bool:
	return not _tokens.is_empty()


func has_token(token: String) -> bool:
	return _tokens.has(token)


func get_tokens() -> Array[String]:
	var tokens: Array[String] = []
	for token in _tokens.keys():
		tokens.append(String(token))
	tokens.sort()
	return tokens
