# src/combat/weapon_controller.gd
class_name WeaponController
extends Node2D

signal damage_dealt(amount: float)

const PROJECTILE_SCENE = preload("res://scenes/combat/projectile.tscn")

const DEFINITIONS := {
	&"soul_bolt": {
		"damage": [12.0, 18.0, 26.0],
		"cooldown": 0.8,
		"counts": [1, 1, 2],
	},
	&"bone_ring": {
		"damage": [8.0, 12.0, 17.0],
		"blades": [2, 3, 4],
		"rotation_speed": 2.4,
	},
	&"nether_flame": {
		"damage": [16.0, 24.0, 34.0],
		"cooldown": 2.8,
		"radii": [56.0, 72.0, 92.0],
		"duration": 1.5,
	},
}

var weapon_levels := {}
var stats := {"damage_mult": 1.0, "attack_speed_mult": 1.0, "life_steal": 0.0}

var cooldown_timers := {
	&"soul_bolt": 0.0,
	&"nether_flame": 0.0,
}

var bone_ring_angle := 0.0
var bone_hit_history := {} # enemy_instance_id -> time_last_hit
var active_flames: Array[Dictionary] = [] # list of {pos, radius, left, duration, warning_left, damage}

func _ready() -> void:
	z_index = 14

func set_loadout(levels: Dictionary, new_stats: Dictionary) -> void:
	weapon_levels = levels.duplicate(true)
	stats = new_stats.duplicate(true)
	queue_redraw()

func nearest_target(origin: Vector2, candidates: Array) -> Node2D:
	var best: Node2D = null
	var best_distance := INF
	for candidate in candidates:
		if not is_instance_valid(candidate) or candidate.get("dead") == true:
			continue
		var candidate_node := candidate as Node2D
		if candidate_node:
			var dist := origin.distance_squared_to(candidate_node.global_position)
			if dist < best_distance:
				best = candidate_node
				best_distance = dist
	return best

func weapon_damage(id: StringName) -> float:
	var level := int(weapon_levels.get(id, 0))
	if level <= 0:
		return 0.0
	var base_list: Array = DEFINITIONS[id].damage
	return float(base_list[level - 1]) * float(stats.get("damage_mult", 1.0))

func weapon_cooldown(id: StringName) -> float:
	var base_cd: float = float(DEFINITIONS[id].cooldown)
	return base_cd / float(stats.get("attack_speed_mult", 1.0))

func record_damage(amount: float) -> void:
	if amount > 0.0:
		damage_dealt.emit(amount)

func _process(delta: float) -> void:
	var enemies := get_tree().get_nodes_in_group("enemies") if get_tree() else []

	# 1. Soul Bolt
	if weapon_levels.get(&"soul_bolt", 0) > 0:
		cooldown_timers[&"soul_bolt"] -= delta
		if cooldown_timers[&"soul_bolt"] <= 0.0:
			var target := nearest_target(global_position, enemies)
			if target:
				cooldown_timers[&"soul_bolt"] = weapon_cooldown(&"soul_bolt")
				_fire_soul_bolt(target)

	# 2. Bone Ring
	if weapon_levels.get(&"bone_ring", 0) > 0:
		var level := int(weapon_levels[&"bone_ring"])
		var blade_count: int = DEFINITIONS[&"bone_ring"].blades[level - 1]
		var rot_speed: float = DEFINITIONS[&"bone_ring"].rotation_speed
		bone_ring_angle += rot_speed * delta
		var radius := 64.0
		var now := Time.get_ticks_msec() / 1000.0
		
		for i in range(blade_count):
			var angle := bone_ring_angle + (i * TAU / blade_count)
			var blade_pos := global_position + Vector2(cos(angle), sin(angle)) * radius
			for enemy in enemies:
				if is_instance_valid(enemy) and enemy.has_method("take_damage") and enemy.get("dead") != true:
					var enemy_node := enemy as Node2D
					if enemy_node and blade_pos.distance_to(enemy_node.global_position) < 24.0:
						var eid := enemy.get_instance_id()
						var last_hit: float = float(bone_hit_history.get(eid, 0.0))
						if now - last_hit >= 0.45:
							bone_hit_history[eid] = now
							var dmg := weapon_damage(&"bone_ring")
							if enemy.take_damage(dmg, self):
								record_damage(dmg)

	# 3. Nether Flame
	if weapon_levels.get(&"nether_flame", 0) > 0:
		cooldown_timers[&"nether_flame"] -= delta
		if cooldown_timers[&"nether_flame"] <= 0.0 and not enemies.is_empty():
			cooldown_timers[&"nether_flame"] = weapon_cooldown(&"nether_flame")
			_spawn_nether_flame(enemies)

	# Process active flames
	var next_flames: Array[Dictionary] = []
	for flame in active_flames:
		if flame.warning_left > 0.0:
			flame.warning_left -= delta
			next_flames.append(flame)
		else:
			flame.left -= delta
			# Damage enemies inside flame radius every 0.3s
			flame.tick_timer = flame.get("tick_timer", 0.0) - delta
			if flame.tick_timer <= 0.0:
				flame.tick_timer = 0.3
				for enemy in enemies:
					if is_instance_valid(enemy) and enemy.has_method("take_damage") and enemy.get("dead") != true:
						var enemy_node := enemy as Node2D
						if enemy_node and flame.pos.distance_to(enemy_node.global_position) < flame.radius:
							if enemy.take_damage(flame.damage, self):
								record_damage(flame.damage)
			if flame.left > 0.0:
				next_flames.append(flame)
	active_flames = next_flames
	queue_redraw()

func _fire_soul_bolt(target: Node2D) -> void:
	var level := int(weapon_levels[&"soul_bolt"])
	var count: int = DEFINITIONS[&"soul_bolt"].counts[level - 1]
	var dmg := weapon_damage(&"soul_bolt")
	var dir := (target.global_position - global_position).normalized()
	
	var world_node: Node = get_tree().current_scene if is_inside_tree() and get_tree().current_scene else get_parent()
	if world_node == get_parent() and get_parent() and get_parent().get_parent():
		world_node = get_parent().get_parent()

	for i in range(count):
		var shot := PROJECTILE_SCENE.instantiate() as Projectile
		world_node.add_child(shot)
		shot.global_position = global_position
		var spread_angle := (i - (count - 1) / 2.0) * 0.2
		shot.launch(dir.rotated(spread_angle), 380.0, dmg, &"player", 2.0)


func _spawn_nether_flame(enemies: Array) -> void:
	var level := int(weapon_levels[&"nether_flame"])
	var radius: float = DEFINITIONS[&"nether_flame"].radii[level - 1]
	var duration: float = DEFINITIONS[&"nether_flame"].duration
	var dmg: float = weapon_damage(&"nether_flame")
	
	# Find densest cluster from candidates
	var best_pos := global_position
	var max_count := -1
	var sample_count: int = mini(8, enemies.size())
	for i in range(sample_count):
		var cand: Node2D = enemies[i] as Node2D
		if is_instance_valid(cand):
			var pos := cand.global_position
			var count := 0
			for other in enemies:
				var other_node: Node2D = other as Node2D
				if is_instance_valid(other_node) and pos.distance_to(other_node.global_position) <= radius:
					count += 1
			if count > max_count:
				max_count = count
				best_pos = pos

				
	active_flames.append({
		"pos": best_pos,
		"radius": radius,
		"left": duration,
		"duration": duration,
		"warning_left": 0.3,
		"damage": dmg,
		"tick_timer": 0.0,
	})

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var outline_color := Color(0, 0, 0, 0.95)
	var offsets := [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5), Vector2(0, 2.0)]

	# Bone Ring text
	if weapon_levels.get(&"bone_ring", 0) > 0:
		var level := int(weapon_levels[&"bone_ring"])
		var blade_count: int = DEFINITIONS[&"bone_ring"].blades[level - 1]
		var radius := 64.0
		var text := "骨刃環"
		var font_size := 18
		var ascent := font.get_ascent(font_size)
		var descent := font.get_descent(font_size)
		var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		var text_offset := Vector2(-string_size.x / 2.0, (ascent - descent) / 2.0)

		for i in range(blade_count):
			var angle := bone_ring_angle + (i * TAU / blade_count)
			var b_pos := Vector2(cos(angle), sin(angle)) * radius
			for off in offsets:
				draw_string(font, b_pos + text_offset + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
			draw_string(font, b_pos + text_offset, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.98, 0.8, 1.0))

	# Nether Flame text
	for flame in active_flames:
		var local_pos := to_local(flame.pos)
		if flame.warning_left > 0.0:
			draw_circle(local_pos, flame.radius, Color(0.6, 0.1, 0.7, 0.3))
		else:
			draw_circle(local_pos, flame.radius, Color(0.4, 0.0, 0.6, 0.35))
			var flame_text := "冥火法陣"
			var font_size := 22
			var ascent := font.get_ascent(font_size)
			var descent := font.get_descent(font_size)
			var string_size := font.get_string_size(flame_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
			var text_offset := Vector2(-string_size.x / 2.0, (ascent - descent) / 2.0)
			for off in offsets:
				draw_string(font, local_pos + text_offset + off, flame_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
			draw_string(font, local_pos + text_offset, flame_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(0.9, 0.5, 1.0, 0.95))
