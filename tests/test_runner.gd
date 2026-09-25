extends SceneTree

const SimulationTests = preload("res://tests/test_simulation.gd")


func _init() -> void:
	var suite = SimulationTests.new()
	var exit_code: int = suite.run()
	quit(exit_code)
