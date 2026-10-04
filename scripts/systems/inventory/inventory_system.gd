class_name InventorySystem
extends RefCounted

signal changed(items: Dictionary)

var items: Dictionary = {}

func _init() -> void:
    var file := FileAccess.open("res://data/reagents/reagents.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for reagent in parsed.get("reagents", []):
            items[str(reagent["id"])] = 0
    items["herb"] = 5
    items["mushroom"] = 4
    items["crystal"] = 3
    items["flower"] = 3

func has_items(requirements: Dictionary) -> bool:
    for id in requirements:
        if int(items.get(id, 0)) < int(requirements[id]):
            return false
    return true

func consume(requirements: Dictionary) -> bool:
    if not has_items(requirements):
        return false
    for id in requirements:
        items[id] = int(items.get(id, 0)) - int(requirements[id])
    changed.emit(items)
    return true

func add_item(id: String, amount: int = 1) -> void:
    items[id] = int(items.get(id, 0)) + amount
    changed.emit(items)
