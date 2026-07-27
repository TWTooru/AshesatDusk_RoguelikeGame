# tests/integration/test_game_flow.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Controller = preload("res://src/core/game_controller.gd")
const RunConfig = preload("res://src/core/run_config.gd")
const GamePhase = preload("res://src/core/game_phase.gd")
var test := TestCase.new()

func _initialize() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	root.add_child(main)
	var controller := main.get_node("GameController") as Controller
	var finished_count := [0]
	controller.run_finished.connect(func(_summary): finished_count[0] += 1)
	controller.start_run(RunConfig.demo())
	test.equal(controller.current_room, 1, "run starts in first room")
	controller.finish_run(&"death")
	controller.finish_run(&"timeout")
	test.equal(finished_count[0], 1, "finish is idempotent")
	test.equal(controller.phase, GamePhase.Phase.RESULTS, "results phase")
	main.free()
	test.finish(self)
