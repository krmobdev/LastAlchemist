class_name StorySystem
extends RefCounted

signal milestone_reached(id: String, data: Dictionary)
signal act_changed(act: Dictionary)

var acts: Array[Dictionary] = []
var milestones: Dictionary = {}
var reached: Dictionary = {}
var current_act := 0

func _init() -> void:
    var file := FileAccess.open("res://data/story/story.json", FileAccess.READ)
    if file == null:
        return
    var parsed = JSON.parse_string(file.get_as_text())
    if parsed is Dictionary:
        for act in parsed.get("acts", []):
            acts.append(act)
        milestones = parsed.get("milestones", {})

func check_progress(reputation: int, world: WorldSystem, known_recipes: Dictionary) -> void:
    _reach_if("first_potion", not known_recipes.is_empty())
    _reach_if("reputation_2", reputation >= 2)
    _reach_if("forest_unlocked", world.unlocked.has("forest"))
    _reach_if("quarry_unlocked", world.unlocked.has("quarry"))
    _reach_if("ruins_unlocked", world.unlocked.has("sun_ruins"))
    _advance_act(reputation)

func reach(id: String) -> bool:
    if reached.has(id) or not milestones.has(id):
        return false
    reached[id] = true
    milestone_reached.emit(id, milestones[id])
    return true

func _reach_if(id: String, condition: bool) -> void:
    if condition:
        reach(id)

func _advance_act(reputation: int) -> void:
    var next := current_act
    for i in range(acts.size()):
        if reputation >= int(acts[i].get("required_reputation", 0)):
            next = i
    if next != current_act and next < acts.size():
        current_act = next
        act_changed.emit(acts[current_act])

func get_current_act() -> Dictionary:
    if current_act < acts.size():
        return acts[current_act]
    return {}
