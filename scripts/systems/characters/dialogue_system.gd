class_name DialogueSystem
extends RefCounted

var dialogues: Dictionary = {}

func _init() -> void:
    var file := FileAccess.open("res://data/dialogue/dialogues.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        dialogues = parsed.get("dialogues", {})

func get_lines(character_id: String) -> Array:
    return dialogues.get(character_id, [])
