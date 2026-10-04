class_name OrderDatabase
extends RefCounted

var orders: Array[Dictionary] = []

func _init() -> void:
    var file := FileAccess.open("res://data/orders/orders.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for order in parsed.get("orders", []):
            orders.append(order)

func get_order(id: String) -> Dictionary:
    for order in orders:
        if str(order.get("id", "")) == id:
            return order
    return {}
