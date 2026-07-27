# tests/unit/test_boss.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Boss = preload("res://src/enemies/boss.gd")
var test := TestCase.new()

func _initialize() -> void:
	var boss := Boss.new()
	var observed: Array[StringName] = []
	for index in 3:
		observed.append(boss.choose_next_attack())
	test.equal(observed, [&"charge", &"tombstones", &"ring"], "readable fixed rotation")
	boss.current_health = boss.max_health * 0.49
	test.check(boss.attack_interval() < boss.base_attack_interval, "phase two accelerates")
	boss.free()
	test.finish(self)
