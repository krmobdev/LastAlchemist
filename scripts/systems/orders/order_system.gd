class_name OrderSystem
extends RefCounted

signal completed(reward: int)
signal order_changed(order: Dictionary)

var orders: Array[Dictionary] = []
var order_index := 0
var active: Dictionary = {}
var reputation := 0

func _init() -> void:
    var file := FileAccess.open("res://data/orders/orders.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for order in parsed.get("orders", []):
            orders.append(order)
    if not orders.is_empty():
        active = orders[0]

func next_order() -> Dictionary:
    if orders.is_empty():
        active = {}
        return active
    order_index = (order_index + 1) % orders.size()
    active = orders[order_index]
    order_changed.emit(active)
    return active

func fulfill(recipe_id: String) -> Dictionary:
    if active.is_empty() or recipe_id != str(active.get("recipe", "")):
        return {"success": false, "message": "Клиент просил другое зелье."}
    reputation += int(active.get("reputation", 1))
    var reward := int(active.get("reward", 0))
    completed.emit(reward)
    return {"success": true, "reward": reward, "message": "Заказ выполнен!"}
