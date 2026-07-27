# tests/unit/test_enemy_and_projectile.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Enemy = preload("res://src/enemies/enemy.gd")
const Projectile = preload("res://src/combat/projectile.gd")
var test := TestCase.new()

func _initialize() -> void:
	var enemy := Enemy.new()
	enemy.configure(&"zombie", 1.5, null)
	test.equal(enemy.max_health, 45.0, "zombie base 30 scaled by difficulty")
	test.check(not enemy.take_damage(44.0), "nonlethal hit reports false")
	test.check(enemy.take_damage(1.0), "lethal hit reports true")
	var shot := Projectile.new()
	shot.launch(Vector2.RIGHT, 500.0, 12.0, &"player", 2.0)
	test.equal(shot.velocity, Vector2(500.0, 0.0), "launch velocity")
	test.equal(shot.damage, 12.0, "launch damage")
	enemy.free()
	shot.free()
	test.finish(self)
