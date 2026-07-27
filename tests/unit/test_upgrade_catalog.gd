# tests/unit/test_upgrade_catalog.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Catalog = preload("res://src/upgrades/upgrade_catalog.gd")
var test := TestCase.new()

func _initialize() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4701
	var stats := {"max_health": 100.0, "health": 40.0, "move_speed": 260.0,
		"damage_mult": 1.0, "attack_speed_mult": 1.0, "damage_reduction": 0.0, "life_steal": 0.0}
	var weapons := {&"soul_bolt": 3, &"bone_ring": 3, &"nether_flame": 3}
	var picks := Catalog.choices(rng, stats, weapons, 3)
	test.equal(picks.size(), 3, "always fills three cards")
	var unique := {}
	for pick in picks:
		unique[pick] = true
	test.equal(unique.size(), 3, "cards are unique")
	test.check(&"soul_bolt" not in picks, "max weapon is excluded")
	var result := Catalog.apply(&"max_health", stats, weapons)
	test.equal(result.stats.max_health, 120.0, "health cap increases by twenty")
	test.equal(result.stats.health, 60.0, "increase also heals twenty")
	test.finish(self)
