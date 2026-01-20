## Test Runner - Discovers and runs all tests
## Run with: godot --headless --script res://tests/run_tests.gd
extends SceneTree


const TEST_DIR := "res://tests/"


func _init() -> void:
	print("\n========================================")
	print("       GBEAT TEST RUNNER")
	print("========================================\n")

	var test_files := _discover_tests()
	var results := _run_tests(test_files)
	_print_results(results)

	# Exit with appropriate code
	if results.failed > 0:
		print("\n[FAIL] %d test(s) failed" % results.failed)
		quit(1)
	else:
		print("\n[PASS] All %d tests passed!" % results.passed)
		quit(0)


func _discover_tests() -> Array[String]:
	var tests: Array[String] = []

	var dir := DirAccess.open(TEST_DIR)
	if not dir:
		push_error("Failed to open tests directory")
		return tests

	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.begins_with("test_") and file_name.ends_with(".gd"):
			tests.append(TEST_DIR + file_name)
		file_name = dir.get_next()

	dir.list_dir_end()

	tests.sort()
	print("Discovered %d test file(s):\n" % tests.size())
	for test in tests:
		print("  - %s" % test.get_file())
	print("")

	return tests


func _run_tests(test_files: Array[String]) -> Dictionary:
	var results := {
		"passed": 0,
		"failed": 0,
		"errors": [],
	}

	for file_path in test_files:
		print("----------------------------------------")
		print("Running: %s" % file_path.get_file())
		print("----------------------------------------")

		var script := load(file_path) as GDScript
		if not script:
			push_error("Failed to load test script: %s" % file_path)
			results.failed += 1
			results.errors.append({
				"file": file_path,
				"test": "load",
				"error": "Failed to load script",
			})
			continue

		var test_instance = script.new()

		# Find and run test methods
		var test_methods := _get_test_methods(script)
		for method_name in test_methods:
			var test_result := _run_single_test(test_instance, method_name)

			if test_result.passed:
				results.passed += 1
				print("  [PASS] %s" % method_name)
			else:
				results.failed += 1
				print("  [FAIL] %s: %s" % [method_name, test_result.error])
				results.errors.append({
					"file": file_path,
					"test": method_name,
					"error": test_result.error,
				})

		# Clean up
		if test_instance.has_method("_cleanup"):
			test_instance._cleanup()

		print("")

	return results


func _get_test_methods(script: GDScript) -> Array[String]:
	var methods: Array[String] = []

	for method in script.get_script_method_list():
		if method.name.begins_with("test_"):
			methods.append(method.name)

	methods.sort()
	return methods


func _run_single_test(instance: Object, method_name: String) -> Dictionary:
	var result := {
		"passed": false,
		"error": "",
	}

	# Run setup if exists
	if instance.has_method("_setup"):
		instance._setup()

	# Run the test
	var test_result = instance.call(method_name)

	# Check result
	if test_result is bool:
		result.passed = test_result
		if not result.passed:
			result.error = "Test returned false"
	elif test_result == null:
		# Assume pass if no exception
		result.passed = true
	else:
		result.passed = false
		result.error = "Invalid test return type"

	# Run teardown if exists
	if instance.has_method("_teardown"):
		instance._teardown()

	return result


func _print_results(results: Dictionary) -> void:
	print("\n========================================")
	print("           TEST RESULTS")
	print("========================================")
	print("Passed: %d" % results.passed)
	print("Failed: %d" % results.failed)
	print("Total:  %d" % (results.passed + results.failed))

	if not results.errors.is_empty():
		print("\n--- FAILURES ---")
		for error in results.errors:
			print("\n%s::%s" % [error.file.get_file(), error.test])
			print("  Error: %s" % error.error)
