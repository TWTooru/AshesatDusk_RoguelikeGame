# tests/unit/test_run_domain.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const GamePhase = preload("res://src/core/game_phase.gd")
const RunConfig = preload("res://src/core/run_config.gd")
var test := TestCase.new()

func _initialize() -> void:
	test.check(GamePhase.can_transition(GamePhase.Phase.TITLE, GamePhase.Phase.COMBAT), "title starts combat")
	test.check(not GamePhase.can_transition(GamePhase.Phase.RESULTS, GamePhase.Phase.COMBAT), "results must restart through title")
	var formal := RunConfig.formal()
	test.equal(formal.room_count, 7, "formal room count")
	test.equal(formal.time_limit_sec, 420.0, "formal time limit")
	test.check(not formal.is_demo, "formal flag")
	var demo := RunConfig.demo()
	test.equal(demo.room_count, 7, "demo still demonstrates seven rooms")
	test.equal(demo.seed_value, 4701, "demo deterministic seed")
	test.check(demo.spawn_scale < 1.0 and demo.is_demo, "demo is accelerated")
	test.finish(self)
