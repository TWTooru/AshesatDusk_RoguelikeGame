# src/player/player.gd
class_name Player
extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal died

const PLAY_BOUNDS := Rect2(48, 112, 1184, 560)

var stats := {
	"max_health": 100.0,
	"health": 100.0,
	"move_speed": 260.0,
	"damage_reduction": 0.0,
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,
	"life_steal": 0.0,
}

var invulnerability_left := 0.0
var control_enabled := true
var dead := false
var facing_direction := Vector2.RIGHT

func _ready() -> void:
	add_to_group("player")
	z_index = 12

func reset_for_run(new_stats: Dictionary) -> void:
	stats = new_stats.duplicate(true)
	if not stats.has("health"):
		stats.health = stats.max_health
	invulnerability_left = 0.0
	control_enabled = true
	dead = false
	queue_redraw()
	health_changed.emit(stats.health, stats.max_health)

func get_stats() -> Dictionary:
	return stats.duplicate(true)

func set_control_enabled(value: bool) -> void:
	control_enabled = value

func set_invulnerability_for_test(value: float) -> void:
	invulnerability_left = value

func heal(amount: float) -> void:
	if dead:
		return
	var old_health: float = stats.health
	stats.health = minf(float(stats.max_health), float(stats.health) + amount)
	if stats.health != old_health:
		health_changed.emit(stats.health, stats.max_health)

func take_damage(amount: float) -> bool:
	if invulnerability_left > 0.0 or dead:
		return false
	var reduction: float = float(stats.get("damage_reduction", 0.0))
	var actual_damage := maxf(1.0, amount * (1.0 - reduction))
	stats.health = maxf(0.0, float(stats.health) - actual_damage)
	invulnerability_left = 0.6
	health_changed.emit(stats.health, stats.max_health)
	queue_redraw()
	if float(stats.health) <= 0.0:
		dead = true
		died.emit()
	return true

func _physics_process(delta: float) -> void:
	invulnerability_left = maxf(0.0, invulnerability_left - delta)
	if invulnerability_left > 0.0:
		queue_redraw()
	if control_enabled and not dead:
		var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_vector != Vector2.ZERO:
			facing_direction = input_vector.normalized()
		velocity = input_vector * float(stats.move_speed)
		move_and_slide()
		global_position = global_position.clamp(PLAY_BOUNDS.position, PLAY_BOUNDS.end)
	else:
		velocity = Vector2.ZERO

func _draw() -> void:
	if dead:
		return
	var font := ThemeDB.fallback_font
	var text := "玩家"
	var font_size := 24
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(-string_size.x / 2.0, (ascent - descent) / 2.0)

	var text_color := Color(1.0, 1.0, 1.0, 1.0) if invulnerability_left > 0.0 else Color(0.9, 0.98, 1.0, 1.0)
	var outline_color := Color(0.0, 0.0, 0.0, 0.95)

	# 4-directional outline
	var offsets := [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5), Vector2(0, 2.0)]
	for off in offsets:
		draw_string(font, text_pos + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	# Main Text
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
