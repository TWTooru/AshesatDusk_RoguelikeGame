# src/presentation/graveyard_backdrop.gd
extends Node2D

const PLAY_AREA := Rect2(32, 96, 1216, 592)
var background_texture: Texture2D

func _ready() -> void:
	if ResourceLoader.exists("res://assets/generated/graveyard_background.png"):
		background_texture = load("res://assets/generated/graveyard_background.png") as Texture2D
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
	var left_door_rect := Rect2(PLAY_AREA.position.x - 4, PLAY_AREA.position.y + PLAY_AREA.size.y * 0.4, 8, PLAY_AREA.size.y * 0.2)
	var right_door_rect := Rect2(PLAY_AREA.end.x - 4, PLAY_AREA.position.y + PLAY_AREA.size.y * 0.4, 8, PLAY_AREA.size.y * 0.2)
	draw_rect(left_door_rect, door_gold)
	draw_rect(right_door_rect, door_gold)
