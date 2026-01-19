## TestBase - Base class for all test cases
class_name TestBase
extends RefCounted


var _last_error: String = ""
var _assertions_count: int = 0


func _setup() -> void:
	_last_error = ""
	_assertions_count = 0


func _teardown() -> void:
	pass


func _cleanup() -> void:
	pass


func get_last_error() -> String:
	return _last_error


## === Assertion Methods ===

func assert_true(condition: bool, message: String = "") -> bool:
	_assertions_count += 1
	if not condition:
		_last_error = message if message else "Expected true, got false"
		return false
	return true


func assert_false(condition: bool, message: String = "") -> bool:
	_assertions_count += 1
	if condition:
		_last_error = message if message else "Expected false, got true"
		return false
	return true


func assert_equal(actual, expected, message: String = "") -> bool:
	_assertions_count += 1
	if actual != expected:
		_last_error = message if message else "Expected %s, got %s" % [expected, actual]
		return false
	return true


func assert_not_equal(actual, not_expected, message: String = "") -> bool:
	_assertions_count += 1
	if actual == not_expected:
		_last_error = message if message else "Expected not %s" % not_expected
		return false
	return true


func assert_null(value, message: String = "") -> bool:
	_assertions_count += 1
	if value != null:
		_last_error = message if message else "Expected null, got %s" % value
		return false
	return true


func assert_not_null(value, message: String = "") -> bool:
	_assertions_count += 1
	if value == null:
		_last_error = message if message else "Expected not null"
		return false
	return true


func assert_greater(actual: float, expected: float, message: String = "") -> bool:
	_assertions_count += 1
	if actual <= expected:
		_last_error = message if message else "Expected %s > %s" % [actual, expected]
		return false
	return true


func assert_less(actual: float, expected: float, message: String = "") -> bool:
	_assertions_count += 1
	if actual >= expected:
		_last_error = message if message else "Expected %s < %s" % [actual, expected]
		return false
	return true


func assert_in_range(value: float, min_val: float, max_val: float, message: String = "") -> bool:
	_assertions_count += 1
	if value < min_val or value > max_val:
		_last_error = message if message else "Expected %s in range [%s, %s]" % [value, min_val, max_val]
		return false
	return true


func assert_array_contains(array: Array, element, message: String = "") -> bool:
	_assertions_count += 1
	if element not in array:
		_last_error = message if message else "Array does not contain %s" % element
		return false
	return true


func assert_array_size(array: Array, expected_size: int, message: String = "") -> bool:
	_assertions_count += 1
	if array.size() != expected_size:
		_last_error = message if message else "Expected array size %d, got %d" % [expected_size, array.size()]
		return false
	return true


func assert_string_contains(string: String, substring: String, message: String = "") -> bool:
	_assertions_count += 1
	if substring not in string:
		_last_error = message if message else "String '%s' does not contain '%s'" % [string, substring]
		return false
	return true


func assert_approximately(actual: float, expected: float, epsilon: float = 0.001, message: String = "") -> bool:
	_assertions_count += 1
	if abs(actual - expected) > epsilon:
		_last_error = message if message else "Expected %s ≈ %s (epsilon: %s)" % [actual, expected, epsilon]
		return false
	return true


func fail(message: String = "Test failed") -> bool:
	_assertions_count += 1
	_last_error = message
	return false
