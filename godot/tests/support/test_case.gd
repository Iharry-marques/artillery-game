class_name TestCase
extends RefCounted
## Minimal base class for headless tests. Every method named test_* is run by
## res://tests/run_tests.gd. Assertions record failures instead of aborting.

var failures: PackedStringArray = []
var notes: PackedStringArray = []


func assert_true(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func assert_near(actual: float, expected: float, tolerance: float, message: String) -> void:
	if is_nan(actual) or absf(actual - expected) > tolerance:
		failures.append("%s: expected %.12f +/- %s, got %.12f (diff %s)" % [
			message, expected, String.num_scientific(tolerance), actual, String.num_scientific(absf(actual - expected))
		])


## Records a measured value so the runner prints it next to the test result.
func note(message: String) -> void:
	notes.append(message)
