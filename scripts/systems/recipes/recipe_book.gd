class_name RecipeBook
extends RefCounted

signal discovered(recipe_id: String)

var known: Dictionary = {}
var recipes: Dictionary = {}

func _init() -> void:
    _load_data()

func _load_data() -> void:
    var file := FileAccess.open("res://data/recipes/recipes.json", FileAccess.READ)
    if file == null:
        push_error("recipes.json not found")
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if not parsed is Dictionary:
        push_error("Invalid recipes.json")
        return
    for recipe in parsed.get("recipes", []):
        recipes[str(recipe["id"])] = recipe

func discover(id: String) -> void:
    if recipes.has(id) and not known.has(id):
        known[id] = true
        discovered.emit(id)

func find_reaction(a: String, b: String) -> String:
    for id in recipes:
        var r: Dictionary = recipes[id]
        if (r["a"] == a and r["b"] == b) or (r["a"] == b and r["b"] == a):
            return id
    return ""
