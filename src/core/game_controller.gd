# src/core/game_controller.gd
class_name GameController
extends Node2D

signal player_health_changed(current: float, maximum: float)
signal player_died
signal enemy_died(kind: StringName)
signal room_cleared(room_index: int)
signal door_selected(reward: Dictionary)
signal upgrade_requested(choices: Array[StringName])
signal upgrade_selected(id: StringName)
signal boss_defeated
signal run_finished(summary: Dictionary)

var phase := GamePhase.Phase.TITLE
var config: RunConfig
var rng := RandomNumberGenerator.new()
var remaining_sec := 420.0
var current_room := 1
var kills := 0
var finished := false
var next_cursed := false

var player_stats := {
	"max_health": 100.0,
	"health": 100.0,
	"move_speed": 260.0,
	"damage_reduction": 0.0,
	"damage_mult": 1.0,
	"attack_speed_mult": 1.0,
	"life_steal": 0.0,
}
var weapon_levels := {&"soul_bolt": 1}

@export var player_node: Player
@export var room_manager: RoomManager
@export var weapon_controller: WeaponController
@export var hud: HUD
@export var title_screen: TitleScreen
@export var upgrade_panel: UpgradePanel
@export var results_screen: ResultsScreen

var pending_upgrade_count := 0
var current_doors: Array[Dictionary] = []

func _ready() -> void:
	if title_screen:
		title_screen.formal_start_requested.connect(func(): start_run(RunConfig.formal()))
		title_screen.demo_start_requested.connect(func(): start_run(RunConfig.demo()))
		title_screen.show()

	if results_screen:
		results_screen.retry_requested.connect(func(): start_run(config if config else RunConfig.formal()))
		results_screen.title_requested.connect(restart_to_title)
		results_screen.hide()

	if upgrade_panel:
		upgrade_panel.upgrade_selected.connect(_on_upgrade_card_selected)
		upgrade_panel.hide()

	if hud:
		hud.door_chosen.connect(select_door)
		hud.pause_requested.connect(toggle_pause)

	if room_manager:
		room_manager.room_cleared.connect(_on_room_cleared)
		room_manager.enemy_killed.connect(_on_enemy_killed)

	if player_node:
		player_node.health_changed.connect(_on_player_health_changed)
		player_node.died.connect(_on_player_died)

	if weapon_controller:
		weapon_controller.damage_dealt.connect(_on_damage_dealt)

	_transition(GamePhase.Phase.TITLE)

func _process(delta: float) -> void:
	if phase == GamePhase.Phase.COMBAT or phase == GamePhase.Phase.DOORS:
		remaining_sec -= delta
		if hud:
			hud.update_timer(maxf(0.0, remaining_sec))
		if remaining_sec <= 0.0 and not finished:
			finish_run(&"timeout")

func start_run(next_config: RunConfig) -> void:
	config = next_config
	rng.seed = config.seed_value
	remaining_sec = config.time_limit_sec
	current_room = 1
	kills = 0
	finished = false
	next_cursed = false
	
	player_stats = {
		"max_health": 100.0,
		"health": 100.0,
		"move_speed": 260.0,
		"damage_reduction": 0.0,
		"damage_mult": 1.0,
		"attack_speed_mult": 1.0,
		"life_steal": 0.0,
	}
	weapon_levels = {&"soul_bolt": 1}

	if title_screen:
		title_screen.hide()
	if results_screen:
		results_screen.hide()
	if hud:
		hud.hide_doors()
		hud.update_health(100.0, 100.0)
		hud.update_room(1)

	if player_node:
		player_node.global_position = Vector2(640, 400)
		player_node.reset_for_run(player_stats)
		
	if weapon_controller:
		weapon_controller.set_loadout(weapon_levels, player_stats)

	get_tree().paused = false
	_transition(GamePhase.Phase.COMBAT)
	
	if room_manager:
		room_manager.set_player(player_node)
		room_manager.start_room(RoomPlanner.plan(current_room, false, config))

func finish_run(outcome: StringName) -> void:
	if finished:
		return
	finished = true
	get_tree().paused = true
	_transition(GamePhase.Phase.RESULTS)
	
	var summary := {
		"outcome": outcome,
		"elapsed_sec": config.time_limit_sec - remaining_sec if config else 0.0,
		"kills": kills,
		"rooms_cleared": current_room - 1 if outcome != &"victory" else 7,
		"weapons": weapon_levels.duplicate(true),
		"stats": player_node.get_stats() if player_node else player_stats,
		"demo": config.is_demo if config else false,
	}
	run_finished.emit(summary)
	if results_screen:
		results_screen.show_results(summary)

func restart_to_title() -> void:
	get_tree().paused = false
	finished = false
	if room_manager:
		room_manager.cleanup_room()
	if hud:
		hud.hide_doors()
	if upgrade_panel:
		upgrade_panel.hide()
	if results_screen:
		results_screen.hide()
	if title_screen:
		title_screen.show()
	_transition(GamePhase.Phase.TITLE)

func toggle_pause() -> void:
	if phase == GamePhase.Phase.COMBAT:
		_transition(GamePhase.Phase.PAUSED)
		get_tree().paused = true
	elif phase == GamePhase.Phase.PAUSED:
		_transition(GamePhase.Phase.COMBAT)
		get_tree().paused = false

func request_upgrade(count: int) -> void:
	pending_upgrade_count = count
	_show_next_upgrade()

func _show_next_upgrade() -> void:
	if pending_upgrade_count <= 0:
		get_tree().paused = false
		_transition(GamePhase.Phase.COMBAT)
		return

	_transition(GamePhase.Phase.UPGRADE)
	get_tree().paused = true
	var choices := UpgradeCatalog.choices(rng, player_stats, weapon_levels, 3)
	upgrade_requested.emit(choices)
	if upgrade_panel:
		upgrade_panel.show_choices(choices)

func _on_upgrade_card_selected(id: StringName) -> void:
	var res := UpgradeCatalog.apply(id, player_stats, weapon_levels)
	player_stats = res.stats
	weapon_levels = res.weapons
	upgrade_selected.emit(id)
	
	if player_node:
		player_node.reset_for_run(player_stats)
	if weapon_controller:
		weapon_controller.set_loadout(weapon_levels, player_stats)
	if hud:
		hud.show_message("取得: " + res.message, 1.5)

	pending_upgrade_count -= 1
	if pending_upgrade_count > 0:
		_show_next_upgrade()
	else:
		get_tree().paused = false
		if current_doors.is_empty():
			_transition(GamePhase.Phase.COMBAT)
		else:
			_transition(GamePhase.Phase.DOORS)

func select_door(door_idx: int) -> void:
	if door_idx < 0 or door_idx >= current_doors.size():
		return
	var door := current_doors[door_idx]
	door_selected.emit(door)
	current_doors.clear()
	if hud:
		hud.hide_doors()

	# Apply door reward
	var dtype: StringName = door.type
	if dtype == &"curse":
		next_cursed = true
	
	if door.upgrade_count > 0:
		request_upgrade(door.upgrade_count)
	elif dtype == &"heal":
		player_stats.max_health = float(player_stats.max_health) + 5.0
		player_stats.health = minf(float(player_stats.max_health), float(player_stats.health) + 35.0)
		if player_node:
			player_node.reset_for_run(player_stats)
		if hud:
			hud.show_message("療癒聖泉: +35 生命, +5 上限", 2.0)
		_advance_to_next_room()
	else:
		_advance_to_next_room()

func _on_room_cleared(room_idx: int) -> void:
	room_cleared.emit(room_idx)
	if room_idx == 7:
		boss_defeated.emit()
		finish_run(&"victory")
		return

	_transition(GamePhase.Phase.DOORS)
	current_doors = RoomPlanner.door_choices(room_idx, rng)
	if hud:
		hud.show_doors(current_doors)

func _advance_to_next_room() -> void:
	current_room += 1
	if hud:
		hud.update_room(current_room)
	if player_node:
		player_node.global_position = Vector2(640, 400)
	_transition(GamePhase.Phase.COMBAT)
	if room_manager:
		var plan := RoomPlanner.plan(current_room, next_cursed, config)
		next_cursed = false
		room_manager.start_room(plan)

func _on_player_health_changed(current: float, maximum: float) -> void:
	player_health_changed.emit(current, maximum)
	if hud:
		hud.update_health(current, maximum)

func _on_player_died() -> void:
	player_died.emit()
	finish_run(&"death")

func _on_enemy_killed(kind: StringName) -> void:
	kills += 1
	enemy_died.emit(kind)

func _on_damage_dealt(amount: float) -> void:
	var l_steal := float(player_stats.get("life_steal", 0.0))
	if l_steal > 0.0 and player_node:
		player_node.heal(amount * l_steal)

func _transition(to: GamePhase.Phase) -> void:
	if phase == to:
		return
	if GamePhase.can_transition(phase, to):
		phase = to
