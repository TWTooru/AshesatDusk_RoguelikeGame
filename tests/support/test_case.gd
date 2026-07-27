# tests/support/test_case.gd
class_name TestCase
extends RefCounted

var failures := 0

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)
		print("FAIL: ", message)

func equal(actual: Variant, expected: Variant, message: String) -> void:
	check(actual == expected, "%s: expected %s, got %s" % [message, expected, actual])

func finish(tree: SceneTree) -> void:
	if failures > 0:
		print("FAILED with ", failures, " failure(s).")
	else:
		print("PASSED")
	tree.quit(1 if failures > 0 else 0)
