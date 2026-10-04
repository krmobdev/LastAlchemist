class_name OrderSystem
extends RefCounted

signal completed(reward: int)

var active: Dictionary = {}
var reputation := 0

func _init() -> void:
    var file := FileAccess.open("res://data/orders/orders.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary and parsed.get("orders", []).size() > 0:
        active = parsed["orders"][0]

func fulfill(recipe_id: String) -> Dictionary:
    if active.is_empty() or recipe_id != str(active.get("recipe", "")):
        return {"success": false, "message": "Клиент просил другое зелье."}
    reputation += int(active.get("reputation", 1))
    var reward := int(active.get("reward", 0))
    completed.emit(reward)
    return {"success": true, "reward": reward, "message": "Заказ выполнен!"}
