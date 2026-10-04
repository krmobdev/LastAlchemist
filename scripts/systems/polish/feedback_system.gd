class_name FeedbackSystem
extends RefCounted

func success() -> void:
    _vibrate(35)

func failure() -> void:
    _vibrate(70)

func click() -> void:
    _vibrate(12)

func _vibrate(duration_ms: int) -> void:
    if OS.has_feature("android"):
        Input.vibrate_handheld(duration_ms)
