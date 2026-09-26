extends SceneTree

# VESPERBELL test runner.
#   godot --headless --path . --script res://tests/test_runner.gd
# Exits 0 when every check passes, 1 otherwise.

const SUITES := [
	"res://tests/test_sim.gd",
	"res://tests/test_state.gd"
]


func _init() -> void:
	var total_failures := 0
	var total_checks := 0
	for suite_path in SUITES:
		var suite_script = load(suite_path)
		var suite = suite_script.new()
		for method in suite.get_method_list():
			var method_name: String = str(method["name"])
			if not method_name.begins_with("test_"):
				continue
			var before: int = suite.failures.size()
			suite.call(method_name)
			for i in range(before, suite.failures.size()):
				print("FAIL [%s · %s] %s" % [suite_path.get_file(), method_name, suite.failures[i]])
				total_failures += 1
		print("%s: %d checks, %d failed" % [suite_path.get_file(), suite.checks, suite.failures.size()])
		total_checks += suite.checks
	print("")
	if total_failures > 0:
		print("TESTS FAILED — %d of %d checks" % [total_failures, total_checks])
		quit(1)
	else:
		print("ALL TESTS PASSED — %d checks" % total_checks)
		quit(0)
