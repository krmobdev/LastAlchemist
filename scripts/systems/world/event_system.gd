class_name WorldEventSystem
extends RefCounted

var events: Array[Dictionary] = []
var cursor := 0

func _init() -> void:
    var file := FileAccess.open("res://data/world/events.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for event in parsed.get("events", []):
            events.append(event)

func event_for(location_id: String) -> Dictionary:
    var matches: Array[Dictionary] = []
    for event in events:
        if str(event.get("location", "")) == location_id:
            matches.append(event)
    if matches.is_empty():
        return {}
    var result := matches[cursor % matches.size()]
    cursor += 1
    return result
