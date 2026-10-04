class_name WorldSystem
extends RefCounted

signal location_unlocked(location_id: String)
signal gathered(item_id: String, amount: int)

var locations: Dictionary = {}
var unlocked: Dictionary = {"village": true}
var current_location := "village"
var gather_counts: Dictionary = {}

func _init() -> void:
    var file := FileAccess.open("res://data/world/locations.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for location in parsed.get("locations", []):
            locations[str(location["id"])] = location

func can_unlock(id: String, reputation: int) -> bool:
    if not locations.has(id):
        return false
    return reputation >= int(locations[id].get("unlock_reputation", 999))

func unlock(id: String, reputation: int) -> bool:
    if unlocked.has(id) or not can_unlock(id, reputation):
        return false
    unlocked[id] = true
    location_unlocked.emit(id)
    return true

func travel(id: String) -> bool:
    if not unlocked.has(id):
        return false
    current_location = id
    return true

func gather() -> Dictionary:
    if not locations.has(current_location):
        return {}
    var pool: Array = locations[current_location].get("gather", [])
    if pool.is_empty():
        return {}
    var index := int(gather_counts.get(current_location, 0)) % pool.size()
    gather_counts[current_location] = index + 1
    var item := str(pool[index])
    gathered.emit(item, 1)
    return {"item": item, "amount": 1}
