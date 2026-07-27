# src/enemies/enemy.gd
class_name Enemy
extends CharacterBody2D

signal died(enemy: Node, kind: StringName)

const PROFILES := {
	&"zombie": {"hp": 30.0, "speed": 65.0, "contact": 10.0},
	&"archer": {"hp": 24.0, "speed": 78.0, "contact": 8.0},
	&"bat": {"hp": 18.0, "speed": 105.0, "contact": 9.0},
	&"knight": {"hp": 110.0, "speed": 48.0, "contact": 18.0},
}

var kind := &"zombie"
var max_health := 30.0
var current_health := 30.0
var move_speed := 65.0
var contact_damage := 10.0
var target: Node2D
var dead := false
var contact_cooldown_left := 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 2 # Enemy layer
	collision_mask = 3  # Player + Enemy layers

func configure(kind_id: StringName, difficulty: float, new_target: Node2D) -> void:
	kind = kind_id
	target = new_target
	var profile: Dictionary = PROFILES.get(kind, PROFILES[&"zombie"])
	max_health = float(profile.hp) * difficulty
	current_health = max_health
	move_speed = float(profile.speed) * minf(1.35, 0.9 + difficulty * 0.1)
	contact_damage = float(profile.contact) * difficulty
	queue_redraw()

func take_damage(amount: float, _source: Node = null) -> bool:
	if dead:
		return false
	current_health = maxf(0.0, current_health - amount)
	queue_redraw()
	if current_health > 0.0:
		return false
	dead = true
	died.emit(self, kind)
	queue_free()
	return true

func _physics_process(delta: float) -> void:
	if dead:
		return
	contact_cooldown_left = maxf(0.0, contact_cooldown_left - delta)
	_step_movement(delta)
	_check_contact_damage()

func _step_movement(_delta: float) -> void:
	if is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()

func _check_contact_damage() -> void:
	if contact_cooldown_left <= 0.0 and is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		if dist < 18.0 and target.has_method("take_damage"):
			if target.take_damage(contact_damage):
				contact_cooldown_left = 0.8

func _draw() -> void:
	if dead:
		return
	match kind:
		&"zombie":
			draw_circle(Vector2.ZERO, 8.0, Color(0.3, 0.5, 0.35, 1.0))
			draw_circle(Vector2(2, -2), 1.5, Color(0.9, 0.1, 0.1, 1.0))
		&"archer":
			draw_rect(Rect2(-6, -6, 12, 12), Color(0.5, 0.4, 0.3, 1.0))
			draw_line(Vector2(-8, 0), Vector2(-4, -6), Color(0.8, 0.8, 0.8, 1.0), 2.0)
		&"bat":
			draw_set_transform(Vector2.ZERO, 0, Vector2(1, 1))
			draw_colored_polygon(PackedVector2Array([Vector2(-9, -4), Vector2(0, 6), Vector2(9, -4), Vector2(0, 0)]), Color(0.35, 0.15, 0.45, 1.0))
		&"knight":
			draw_rect(Rect2(-10, -12, 20, 24), Color(0.25, 0.25, 0.35, 1.0))
			draw_rect(Rect2(-8, -10, 16, 6), Color(0.8, 0.7, 0.2, 1.0)) # Gold helmet trim
