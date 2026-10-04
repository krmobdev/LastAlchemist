class_name AudioSystem
extends Node

var enabled := true
var master_volume := 1.0

func set_enabled(value: bool) -> void:
    enabled = value

func set_volume(value: float) -> void:
    master_volume = clampf(value, 0.0, 1.0)

# Audio assets are intentionally data-driven and can be added without touching gameplay systems.
func play_ui_click() -> void:
    pass

func play_brew_success() -> void:
    pass

func play_brew_failure() -> void:
    pass
