extends RefCounted

const Inventory = preload("res://scripts/systems/inventory/inventory_system.gd")
const Recipes = preload("res://scripts/systems/recipes/recipe_book.gd")
const Economy = preload("res://scripts/systems/economy/economy_system.gd")

func run() -> Array[String]:
    var failures: Array[String] = []
    var inv = Inventory.new()
    if not inv.has_items({"herb": 1, "flower": 1}):
        failures.append("initial inventory")
    if not inv.consume({"herb": 1, "flower": 1}):
        failures.append("inventory consume")
    var book = Recipes.new()
    if book.find_reaction("herb", "flower") != "healing":
        failures.append("healing reaction")
    if book.find_reaction("flower", "herb") != "healing":
        failures.append("reverse reaction")
    var economy = Economy.new()
    economy.earn(100)
    if not economy.spend(50) or economy.gold != 150:
        failures.append("economy")
    return failures
