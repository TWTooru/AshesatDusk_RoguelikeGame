# src/enemies/ranged_enemy.gd
class_name RangedEnemy
extends Enemy

const PROJECTILE_SCENE = preload("res://scenes/combat/projectile.tscn")

var shoot_cooldown_left := 1.5
var warning_left := 0.0

func _step_movement(delta: float) -> void:
	shoot_cooldown_left -= delta
	if warning_left > 0.0:
		warning_left -= delta
		velocity = Vector2.ZERO
		queue_redraw()
		if warning_left <= 0.0:
			_fire_arrow()
		return
		
	if shoot_cooldown_left <= 0.0:
		shoot_cooldown_left = 2.2
		warning_left = 0.4
		velocity = Vector2.ZERO
		queue_redraw()
		return

	if is_instance_valid(target):
		var dist := global_position.distance_to(target.global_position)
		var dir := (target.global_position - global_position).normalized()
		if dist < 240.0:
			velocity = -dir * move_speed
		elif dist > 330.0:
			velocity = dir * move_speed
		else:
			velocity = Vector2.ZERO
		move_and_slide()

func _fire_arrow() -> void:
	if not is_instance_valid(target) or dead:
		return
	var arrow := PROJECTILE_SCENE.instantiate() as Projectile
	get_parent().add_child(arrow)
	arrow.global_position = global_position
	var dir := (target.global_position - global_position).normalized()
	arrow.launch(dir, 260.0, 10.0 * (max_health / 24.0), &"enemy", 3.0)

func _draw() -> void:
	super._draw()
	if warning_left > 0.0 and is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		draw_line(Vector2.ZERO, dir * 180.0, Color(1.0, 0.1, 0.1, 0.6), 1.5)
