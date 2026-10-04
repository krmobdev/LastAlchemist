class_name ShopSystem
extends RefCounted

var stock: Dictionary = {}
var prices: Dictionary = {}
var upgrades: Array[Dictionary] = []

func _init() -> void:
    var file := FileAccess.open("res://data/config/shop.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        return
    for item in parsed.get("items", []):
        var id := str(item["id"])
        prices[id] = int(item["price"])
        stock[id] = int(item["stock"])
    for upgrade in parsed.get("upgrades", []):
        upgrades.append(upgrade)

func buy(id: String, economy: EconomySystem, inventory: InventorySystem) -> bool:
    if not stock.has(id) or int(stock[id]) <= 0:
        return false
    var price := int(prices.get(id, 0))
    if not economy.spend(price):
        return false
    stock[id] = int(stock[id]) - 1
    inventory.add_item(id, 1)
    return true
