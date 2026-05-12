class_name WebSaveStorageAdapter
extends "res://scripts/profile/file_save_storage_adapter.gd"

# Godot's user:// abstraction is used for V0.1 Web builds as well. If a target
# export proves unreliable, this adapter is the single place to add IndexedDB or
# JavaScript bridge behavior without leaking platform checks into UI code.
