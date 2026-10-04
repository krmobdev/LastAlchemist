class_name CharacterDatabase
extends RefCounted

var characters: Dictionary = {}

func _init() -> void:
    var file := FileAccess.open("res://data/characters/characters.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for character in parsed.get("characters", []):
            characters[str(character["id"])] = character
