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
	var font := ThemeDB.fallback_font
	var text_map := {
		&"zombie": "腐屍",
		&"archer": "骸骨弓手",
		&"bat": "暗影蝙蝠",
		&"knight": "墓園騎士",
	}
	var color_map := {
		&"zombie": Color(0.4, 0.7, 0.45, 1.0),
		&"archer": Color(0.75, 0.7, 0.6, 1.0),
		&"bat": Color(0.7, 0.35, 0.8, 1.0),
		&"knight": Color(0.9, 0.8, 0.3, 1.0),
	}
	var text: String = text_map.get(kind, "怪物")
	var text_color: Color = color_map.get(kind, Color.WHITE)
	var font_size := 15
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(-string_size.x / 2.0, (ascent - descent) / 2.0)

	# Shadow & Text
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.8))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)

