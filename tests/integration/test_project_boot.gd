# tests/integration/test_project_boot.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
var test := TestCase.new()

func _initialize() -> void:
	var packed := load("res://scenes/main.tscn") as PackedScene
	test.check(packed != null, "main scene must load")
	if packed:
		var main := packed.instantiate()
		test.equal(main.name, "Main", "composition root name")
		test.check(main.has_node("Backdrop"), "main has fallback backdrop")
		main.free()
	test.finish(self)
