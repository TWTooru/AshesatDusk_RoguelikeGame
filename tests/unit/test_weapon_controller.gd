# tests/unit/test_weapon_controller.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Weapons = preload("res://src/combat/weapon_controller.gd")
var test := TestCase.new()

func _initialize() -> void:
	var controller := Weapons.new()
	var far := Node2D.new()
	far.position = Vector2(90, 0)
	var near := Node2D.new()
	near.position = Vector2(20, 0)
	test.equal(controller.nearest_target(Vector2.ZERO, [far, near]), near, "nearest valid target")
	controller.set_loadout({&"soul_bolt": 2}, {"damage_mult": 1.5, "attack_speed_mult": 2.0})
	test.equal(controller.weapon_damage(&"soul_bolt"), 27.0, "level two damage times multiplier")
	test.equal(controller.weapon_cooldown(&"soul_bolt"), 0.4, "cooldown divided by attack speed")
	far.free()
	near.free()
	controller.free()
	test.finish(self)
