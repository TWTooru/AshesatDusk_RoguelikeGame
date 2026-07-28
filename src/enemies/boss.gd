# src/enemies/boss.gd
class_name Boss
extends Enemy

const PROJECTILE_SCENE = preload("res://scenes/combat/projectile.tscn")
const ENEMY_SCENE = preload("res://scenes/enemies/enemy.tscn")

const ATTACK_ORDER: Array[StringName] = [&"charge", &"tombstones", &"ring"]
var next_attack_index := 0

var base_attack_interval := 3.2
var attack_cooldown := 2.0
var attack_state := &"idle"
var attack_timer := 0.0

# Charge state
var charge_direction := Vector2.ZERO

# Tombstones state
var tombstone_target_positions: Array[Vector2] = []

func _ready() -> void:
	super._ready()
	kind = &"boss"
	max_health = 1200.0
	current_health = 1200.0
	move_speed = 52.0
	contact_damage = 20.0

func choose_next_attack() -> StringName:
	var result := ATTACK_ORDER[next_attack_index]
	next_attack_index = (next_attack_index + 1) % ATTACK_ORDER.size()
	return result

func attack_interval() -> float:
	return 2.35 if current_health < max_health * 0.5 else base_attack_interval

func _step_movement(delta: float) -> void:
	advance_ai(delta)
	if attack_state == &"charging":
		velocity = charge_direction * 520.0
		move_and_slide()
	elif attack_state == &"idle" and is_instance_valid(target):
		var dir := (target.global_position - global_position).normalized()
		velocity = dir * move_speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func advance_ai(delta: float) -> void:
	if dead:
		return

	if attack_state != &"idle":
		attack_timer -= delta
		queue_redraw()
		if attack_state == &"telegraph_charge" and attack_timer <= 0.0:
			attack_state = &"charging"
			attack_timer = 0.7
		elif attack_state == &"charging" and attack_timer <= 0.0:
			_finish_attack()
		elif attack_state == &"telegraph_tombstones" and attack_timer <= 0.0:
			_spawn_tombstones()
			_finish_attack()
		elif attack_state == &"telegraph_ring" and attack_timer <= 0.0:
			_fire_ring()
			_finish_attack()
		return

	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		_begin_attack(choose_next_attack())

func _begin_attack(attack_type: StringName) -> void:
	if not is_instance_valid(target):
		return
	attack_state = &"telegraph_" + String(attack_type)
	
	match attack_type:
		&"charge":
			attack_timer = 0.7
			charge_direction = (target.global_position - global_position).normalized()
		&"tombstones":
			attack_timer = 0.8
			tombstone_target_positions.clear()
			var base_pos := target.global_position
			tombstone_target_positions.append(base_pos + Vector2(-80, -40))
			tombstone_target_positions.append(base_pos + Vector2(80, -40))
			tombstone_target_positions.append(base_pos + Vector2(0, 70))
		&"ring":
			attack_timer = 0.6

func _finish_attack() -> void:
	attack_state = &"idle"
	attack_cooldown = attack_interval()
	tombstone_target_positions.clear()
	queue_redraw()

func _spawn_tombstones() -> void:
	for pos in tombstone_target_positions:
		var tomb := StaticBody2D.new()
		tomb.global_position = pos.clamp(Vector2(60, 120), Vector2(1220, 660))
		tomb.add_to_group("tombstones")
		get_parent().add_child(tomb)
		
		# Spawn zombie after 1 second
		var tree := get_tree()
		if tree:
			tree.create_timer(1.0).timeout.connect(func():
				if is_instance_valid(tomb):
					var zombie := ENEMY_SCENE.instantiate() as Enemy
					get_parent().add_child(zombie)
					zombie.global_position = tomb.global_position
					zombie.configure(&"zombie", 1.2, target)
			)
			tree.create_timer(6.0).timeout.connect(func():
				if is_instance_valid(tomb):
					tomb.queue_free()
			)

func _fire_ring() -> void:
	var total_shots := 18
	var gap1 := 4
	var gap2 := 5
	for i in range(total_shots):
		if i == gap1 or i == gap2:
			continue
		var angle := i * TAU / total_shots
		var dir := Vector2(cos(angle), sin(angle))
		var shot := PROJECTILE_SCENE.instantiate() as Projectile
		get_parent().add_child(shot)
		shot.global_position = global_position
		shot.launch(dir, 150.0, 14.0, &"enemy", 4.0)

func take_damage(amount: float, source: Node = null) -> bool:
	var died_now := super.take_damage(amount, source)
	if died_now:
		# Clean up tombstone objects
		var tombstones := get_tree().get_nodes_in_group("tombstones") if get_tree() else []
		for t in tombstones:
			if is_instance_valid(t):
				t.queue_free()
	return died_now

func _draw() -> void:
	if dead:
		return

	var font := ThemeDB.fallback_font
	var text := "無首守墓人"
	var font_size := 22
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(-string_size.x / 2.0, (ascent - descent) / 2.0)

	# Shadow & Text
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0, 0, 0, 0.9))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.95, 0.3, 0.4, 1.0))


	# Health bar over head
	var hp_ratio := current_health / max_health
	draw_rect(Rect2(-40, -28, 80, 6), Color(0.2, 0.2, 0.2, 0.8))
	draw_rect(Rect2(-40, -28, 80 * hp_ratio, 6), Color(0.8, 0.1, 0.1, 0.9))

	# Attack warnings
	if attack_state == &"telegraph_charge":
		draw_line(Vector2.ZERO, charge_direction * 300.0, Color(1.0, 0.1, 0.1, 0.7), 3.0)
	elif attack_state == &"telegraph_tombstones":
		for pos in tombstone_target_positions:
			var local_pos := to_local(pos)
			draw_circle(local_pos, 18.0, Color(1.0, 0.1, 0.1, 0.5))
	elif attack_state == &"telegraph_ring":
		draw_arc(Vector2.ZERO, 40.0, 0, TAU, 24, Color(1.0, 0.1, 0.1, 0.6), 2.0)
