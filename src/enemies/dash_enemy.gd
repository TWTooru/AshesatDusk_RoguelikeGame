# src/enemies/dash_enemy.gd
class_name DashEnemy
extends Enemy

var dash_cooldown_left := 1.0
var telegraph_left := 0.0
var dash_time_left := 0.0
var dash_direction := Vector2.ZERO

func _step_movement(delta: float) -> void:
	if telegraph_left > 0.0:
		telegraph_left -= delta
		velocity = Vector2.ZERO
		queue_redraw()
		if telegraph_left <= 0.0:
			dash_time_left = 220.0 / 420.0
		return

	if dash_time_left > 0.0:
		dash_time_left -= delta
		velocity = dash_direction * 420.0
		move_and_slide()
		if dash_time_left <= 0.0:
			dash_cooldown_left = 2.0
		return

	dash_cooldown_left -= delta
	if dash_cooldown_left <= 0.0 and is_instance_valid(target):
		telegraph_left = 0.45
		dash_direction = (target.global_position - global_position).normalized()
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()

func _draw() -> void:
	super._draw()
	if telegraph_left > 0.0:
		draw_circle(Vector2.ZERO, 12.0, Color(1.0, 0.1, 0.1, 0.4))
		draw_line(Vector2.ZERO, dash_direction * 80.0, Color(1.0, 0.2, 0.2, 0.8), 2.0)
