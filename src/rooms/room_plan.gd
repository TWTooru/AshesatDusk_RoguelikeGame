# src/rooms/room_plan.gd
class_name RoomPlan
extends RefCounted

var room_index := 1
var difficulty := 1.0
var enemy_counts := {}
var cursed := false
var boss := false

func _init(idx: int, diff: float, counts: Dictionary, is_cursed: bool, is_boss: bool) -> void:
	room_index = idx
	difficulty = diff
	enemy_counts = counts.duplicate(true)
	cursed = is_cursed
	boss = is_boss
