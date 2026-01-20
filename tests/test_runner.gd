## TestRunner - Automated test framework for GBeat
## Run with: godot --headless --script res://tests/test_runner.gd
extends SceneTree


signal all_tests_completed(passed: int, failed: int)


var _test_classes: Array[GDScript] = []
var _passed: int = 0
var _failed: int = 0
var _current_test_class: GDScript = null
var _test_results: Array[Dictionary] = []


func _init() -> void:
	print("\n" + "=".repeat(60))
	print("GBeat Automated Test Suite")
	print("=".repeat(60) + "\n")

	_discover_tests()
	_run_all_tests()

	_print_summary()

	quit(_failed)


func _discover_tests() -> void:
	var test_dir := "res://tests/"
	var dir := DirAccess.open(test_dir)

	if not dir:
		push_error("Failed to open tests directory")
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		# Skip base class and runner itself
		if file_name.begins_with("test_") and file_name.ends_with(".gd") and file_name != "test_base.gd" and file_name != "test_runner.gd":
			var script := load(test_dir + file_name) as GDScript
			if script:
				_test_classes.append(script)
				print("Discovered: %s" % file_name)
		file_name = dir.get_next()

	dir.list_dir_end()
	print("\nFound %d test files\n" % _test_classes.size())


func _run_all_tests() -> void:
	for test_class in _test_classes:
		_run_test_class(test_class)


func _run_test_class(test_class: GDScript) -> void:
	var instance = test_class.new()
	_current_test_class = test_class

	var class_name_str := test_class.resource_path.get_file().get_basename()
	print("\n--- %s ---" % class_name_str)

	# Find all test methods
	var methods: Array = instance.get_method_list()
	for method: Dictionary in methods:
		var method_name: String = method["name"]
		if method_name.begins_with("test_"):
			_run_test_method(instance, method_name, class_name_str)

	# Cleanup
	if instance.has_method("_cleanup"):
		instance._cleanup()

	if instance is Node:
		instance.queue_free()


func _run_test_method(instance: Object, method_name: String, test_class_name: String) -> void:
	# Setup
	if instance.has_method("_setup"):
		instance._setup()

	var result := {"class": test_class_name, "method": method_name, "passed": true, "error": ""}

	# Run test
	var error_msg := ""
	var success := true

	# Try to call the test method
	if instance.has_method(method_name):
		var ret = instance.call(method_name)
		if ret is String and ret != "":
			success = false
			error_msg = ret
		elif ret == false:
			success = false
			error_msg = "Test returned false"

	# Check assertions
	if instance.has_method("get_last_error"):
		var last_error: String = instance.get_last_error()
		if last_error != "":
			success = false
			error_msg = last_error

	# Record result
	if success:
		_passed += 1
		print("  ✓ %s" % method_name)
	else:
		_failed += 1
		print("  ✗ %s: %s" % [method_name, error_msg])
		result["passed"] = false
		result["error"] = error_msg

	_test_results.append(result)

	# Teardown
	if instance.has_method("_teardown"):
		instance._teardown()


func _print_summary() -> void:
	print("\n" + "=".repeat(60))
	print("Test Results: %d passed, %d failed" % [_passed, _failed])
	print("=".repeat(60))

	if _failed > 0:
		print("\nFailed tests:")
		for result in _test_results:
			if not result["passed"]:
				print("  - %s::%s" % [result["class"], result["method"]])
				print("    Error: %s" % result["error"])

	print("")
