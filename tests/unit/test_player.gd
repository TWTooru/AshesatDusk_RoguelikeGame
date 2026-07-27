# tests/unit/test_player.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Player = preload("res://src/player/player.gd")
var test := TestCase.new()

func _initialize() -> void:
	var player := Player.new()
	player.reset_for_run({"max_health": 100.0, "health": 100.0, "move_speed": 260.0,
		"damage_reduction": 0.25, "damage_mult": 1.0, "attack_speed_mult": 1.0, "life_steal": 0.0})
	test.check(player.take_damage(40.0), "first hit applies")
	test.equal(player.get_stats().health, 70.0, "reduction applies")
	test.check(not player.take_damage(40.0), "invulnerability blocks immediate repeat")
	player.set_invulnerability_for_test(0.0)
	player.heal(999.0)
	test.equal(player.get_stats().health, 100.0, "healing clamps")
	player.free()
	test.finish(self)
