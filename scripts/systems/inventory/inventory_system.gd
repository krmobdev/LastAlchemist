class_name InventorySystem
extends RefCounted

signal changed(items: Dictionary)

var items: Dictionary = {"herb": 5, "mushroom": 4, "crystal": 3, "flower": 3}

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
