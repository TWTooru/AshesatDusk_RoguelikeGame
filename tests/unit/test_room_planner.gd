# tests/unit/test_room_planner.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Planner = preload("res://src/rooms/room_planner.gd")
const RunConfig = preload("res://src/core/run_config.gd")
var test := TestCase.new()

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4701
	var first := Planner.plan(1, false, RunConfig.formal())
	test.equal(first.enemy_counts.get(&"zombie", 0), 10, "room one teaches zombies")
	var boss := Planner.plan(7, false, RunConfig.formal())
	test.check(boss.boss and boss.enemy_counts.is_empty(), "room seven is boss only")
	var doors := Planner.door_choices(3, rng)
	test.equal(doors.size(), 2, "two doors")
	test.check(doors[0].type != doors[1].type, "distinct rewards")
	test.finish(self)
