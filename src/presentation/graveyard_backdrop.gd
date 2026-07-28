# src/presentation/graveyard_backdrop.gd
extends Node2D

const PLAY_AREA := Rect2(32, 96, 1216, 592)
var background_texture: Texture2D
var controller: GameController

func _ready() -> void:
	var path := "res://assets/generated/graveyard_background.png"
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			background_texture = res as Texture2D
	if not background_texture:
		var global_path := ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(global_path):
			var img := Image.load_from_file(global_path)
			if img:
				background_texture = ImageTexture.create_from_image(img)
	queue_redraw()

func _process(_delta: float) -> void:
	if not controller:
		var parent := get_parent()
		if parent:
			controller = parent.get_node_or_null("GameController")
	if controller and controller.phase == GamePhase.Phase.DOORS:
		queue_redraw()

func _draw() -> void:
	if background_texture:
		draw_texture_rect(background_texture, Rect2(0, 0, 1280, 720), false)
	else:
		# Dark charcoal floor
		draw_rect(Rect2(0, 0, 1280, 720), Color(0.08, 0.08, 0.1, 1.0))
		
		# Play area floor (slightly lighter dark blue-gray)
		draw_rect(PLAY_AREA, Color(0.11, 0.12, 0.16, 1.0))
		
		# 16-pixel subtle grid lines
		var grid_color := Color(0.15, 0.16, 0.22, 0.4)
		for x in range(int(PLAY_AREA.position.x), int(PLAY_AREA.end.x), 16):
			draw_line(Vector2(x, PLAY_AREA.position.y), Vector2(x, PLAY_AREA.end.y), grid_color, 1.0)
		for y in range(int(PLAY_AREA.position.y), int(PLAY_AREA.end.y), 16):
			draw_line(Vector2(PLAY_AREA.position.x, y), Vector2(PLAY_AREA.end.x, y), grid_color, 1.0)

	# Outer border of play area (32-pixel offset border)
	draw_rect(PLAY_AREA, Color(0.3, 0.35, 0.45, 1.0), false, 3.0)
	
	# Gold exit accents (left door frame & right door frame areas)
	var door_gold := Color(0.9, 0.75, 0.2, 0.8)
	var left_door_rect := Rect2(PLAY_AREA.position.x - 6, PLAY_AREA.position.y + PLAY_AREA.size.y * 0.35, 12, PLAY_AREA.size.y * 0.3)
	var right_door_rect := Rect2(PLAY_AREA.end.x - 6, PLAY_AREA.position.y + PLAY_AREA.size.y * 0.35, 12, PLAY_AREA.size.y * 0.3)
	draw_rect(left_door_rect, door_gold)
	draw_rect(right_door_rect, door_gold)

	# Door Text Labels when doors phase is active
	if controller and controller.phase == GamePhase.Phase.DOORS and not controller.current_doors.is_empty():
		var font := ThemeDB.fallback_font
		var d1: Dictionary = controller.current_doors[0]
		var d2: Dictionary = controller.current_doors[1]
		
		# Left Door Label
		var label1: String = "【走進左門: " + String(d1.get("label", "下一關")) + "】"
		draw_string(font, Vector2(PLAY_AREA.position.x + 16, 390), label1, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.3, 1.0, 0.5))
		
		# Right Door Label
		var label2: String = "【走進右門: " + String(d2.get("label", "下一關")) + "】"
		var size2 := font.get_string_size(label2, HORIZONTAL_ALIGNMENT_LEFT, -1, 20)
		draw_string(font, Vector2(PLAY_AREA.end.x - 16 - size2.x, 390), label2, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.3, 1.0, 0.5))
