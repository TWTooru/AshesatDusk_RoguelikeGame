# tests/integration/test_room_manager.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const RoomManager = preload("res://src/rooms/room_manager.gd")
const RoomPlanner = preload("res://src/rooms/room_planner.gd")
const RunConfig = preload("res://src/core/run_config.gd")
const Player = preload("res://src/player/player.gd")
var test := TestCase.new()

func _initialize() -> void:
	var root_node := Node2D.new()
	root.add_child(root_node)
	
	var player := Player.new()
	root_node.add_child(player)
	
	var room_mgr := RoomManager.new()
	root_node.add_child(room_mgr)
	room_mgr.set_player(player)
	
	var cleared_signal_count := [0]
	room_mgr.room_cleared.connect(func(_idx): cleared_signal_count[0] += 1)
	
	var plan := RoomPlanner.plan(1, false, RunConfig.formal())
	room_mgr.start_room(plan)
	test.equal(room_mgr.live_count, 10, "room one spawns 10 zombies")
	
	# Kill all enemies
	for enemy in room_mgr.active_enemies:
		if is_instance_valid(enemy) and enemy.has_method("take_damage"):
			enemy.take_damage(9999.0)
			
	test.equal(cleared_signal_count[0], 1, "room_cleared fired once")
	
	root_node.free()
	test.finish(self)
