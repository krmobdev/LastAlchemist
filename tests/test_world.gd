extends RefCounted

const World = preload("res://scripts/systems/world/world_system.gd")
const Events = preload("res://scripts/systems/world/event_system.gd")

func run() -> Array[String]:
    var failures: Array[String] = []
    var world = World.new()
    if not world.unlocked.has("village"):
        failures.append("village unlocked")
    if world.can_unlock("forest", 1):
        failures.append("forest locked too early")
    if not world.can_unlock("forest", 2):
        failures.append("forest unlock")
    if not world.unlock("forest", 2) or not world.unlocked.has("forest"):
        failures.append("forest unlock execution")
    if not world.travel("forest") or world.current_location != "forest":
        failures.append("forest travel")
    var events = Events.new()
    if events.event_for("forest").is_empty():
        failures.append("forest event")
    return failures
