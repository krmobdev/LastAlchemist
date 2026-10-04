class_name RecipeBook
extends RefCounted

signal discovered(recipe_id: String)

var known: Dictionary = {}
var recipes := {
    "healing": {"name": "Зелье восстановления", "a": "herb", "b": "flower", "result": "potion", "reward": 40},
    "focus": {"name": "Эликсир концентрации", "a": "crystal", "b": "flower", "result": "potion", "reward": 55},
    "ember": {"name": "Алхимический эликсир", "a": "mushroom", "b": "crystal", "result": "potion", "reward": 70}
}

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
