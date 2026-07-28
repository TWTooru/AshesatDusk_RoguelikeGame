# src/rooms/room_manager.gd
class_name RoomManager
extends Node2D

signal room_cleared(room_index: int)
signal door_selected(reward: Dictionary)
signal enemy_killed(kind: StringName)

const ENEMY_SCENE = preload("res://scenes/enemies/enemy.tscn")
const RANGED_SCRIPT = preload("res://src/enemies/ranged_enemy.gd")
const DASH_SCRIPT = preload("res://src/enemies/dash_enemy.gd")
const BOSS_SCRIPT = preload("res://src/enemies/boss.gd")

const PLAY_BOUNDS := Rect2(48, 112, 1184, 560)

var current_plan: RoomPlan
var active_enemies: Array[Node2D] = []
var live_count := 0
var player_ref: Node2D

func set_player(player: Node2D) -> void:
	player_ref = player

func start_room(plan: RoomPlan) -> void:
	cleanup_room()
	current_plan = plan
	live_count = 0
	
	if plan.boss:
		_spawn_boss(plan.difficulty)
	else:
		_spawn_waves(plan)

func cleanup_room() -> void:
	for enemy in active_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	active_enemies.clear()
	live_count = 0
	
	# Clear projectiles & stray nodes in tree under main/room
	for child in get_children():
		child.queue_free()

func _spawn_waves(plan: RoomPlan) -> void:
	var total := 0
	for kind in plan.enemy_counts:
		total += int(plan.enemy_counts[kind])
	live_count = total
	
	if total == 0:
		room_cleared.emit(plan.room_index)
		return

	var spawn_index := 0
	for kind in plan.enemy_counts:
		var count: int = int(plan.enemy_counts[kind])
		for i in range(count):
			_spawn_enemy(kind, plan.difficulty, spawn_index)
			spawn_index += 1

func _spawn_enemy(kind: StringName, difficulty: float, index: int) -> void:
	var enemy := ENEMY_SCENE.instantiate() as Enemy
	match kind:
		&"archer":
			enemy.set_script(RANGED_SCRIPT)
		&"bat":
			enemy.set_script(DASH_SCRIPT)
		&"knight":
			enemy.set_script(ENEMY_SCENE.instantiate().get_script())
	
	add_child(enemy)
	active_enemies.append(enemy)
	
	var pos := _get_spawn_position(index)
	enemy.global_position = pos
	enemy.configure(kind, difficulty, player_ref)
	enemy.died.connect(_on_enemy_died)

func _spawn_boss(difficulty: float) -> void:
	live_count = 1
	var boss_node := CharacterBody2D.new()
	boss_node.set_script(BOSS_SCRIPT)
	var boss := boss_node as Enemy
	add_child(boss)
	active_enemies.append(boss)
	boss.global_position = Vector2(640, 240)
	boss.configure(&"boss", difficulty, player_ref)
	boss.died.connect(_on_enemy_died)



func _get_spawn_position(index: int) -> Vector2:
	# Distribute around perimeter
	var perimeter := [
		Vector2(PLAY_BOUNDS.position.x + 20, PLAY_BOUNDS.position.y + (index * 37) % int(PLAY_BOUNDS.size.y)),
		Vector2(PLAY_BOUNDS.end.x - 20, PLAY_BOUNDS.position.y + (index * 41) % int(PLAY_BOUNDS.size.y)),
		Vector2(PLAY_BOUNDS.position.x + (index * 43) % int(PLAY_BOUNDS.size.x), PLAY_BOUNDS.position.y + 20),
		Vector2(PLAY_BOUNDS.position.x + (index * 47) % int(PLAY_BOUNDS.size.x), PLAY_BOUNDS.end.y - 20),
	]
	var pos: Vector2 = perimeter[index % 4]
	if is_instance_valid(player_ref):
		if pos.distance_to(player_ref.global_position) < 180.0:
			pos += (pos - player_ref.global_position).normalized() * 120.0
	return pos.clamp(PLAY_BOUNDS.position, PLAY_BOUNDS.end)

func _on_enemy_died(enemy_node: Node, kind: StringName) -> void:
	enemy_killed.emit(kind)
	live_count -= 1
	if live_count <= 0:
		live_count = 0
		if current_plan:
			room_cleared.emit(current_plan.room_index)
