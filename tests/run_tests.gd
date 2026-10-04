extends SceneTree

const Tests = preload("res://tests/test_game_logic.gd")
const WorldTests = preload("res://tests/test_world.gd")

func _init() -> void:
    var failures = Tests.new().run()
    failures.append_array(WorldTests.new().run())
    if failures.is_empty():
        print("ALL LOGIC TESTS PASSED")
        quit(0)
    else:
        for failure in failures:
            push_error("FAIL: " + failure)
        quit(1)
