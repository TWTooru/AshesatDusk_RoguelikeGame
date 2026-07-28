# src/ui/hud.gd
class_name HUD
extends CanvasLayer

signal door_chosen(index: int)
signal pause_requested

@onready var health_label: Label = $TopMargin/HBox/HealthLabel
@onready var room_label: Label = $TopMargin/HBox/RoomLabel
@onready var timer_label: Label = $TopMargin/HBox/TimerLabel
@onready var door_panel: Control = $DoorPanel
@onready var door1_btn: Button = $DoorPanel/HBox/Door1Button
@onready var door2_btn: Button = $DoorPanel/HBox/Door2Button
@onready var message_label: Label = $MessageLabel

var current_doors: Array[Dictionary] = []

func _ready() -> void:
	if door_panel:
		door_panel.hide()
	if message_label:
		message_label.text = ""
	if door1_btn:
		door1_btn.pressed.connect(func(): door_chosen.emit(0))
	if door2_btn:
		door2_btn.pressed.connect(func(): door_chosen.emit(1))

func update_health(current: float, maximum: float) -> void:
	if health_label:
		health_label.text = "生命: %d / %d" % [int(ceil(current)), int(ceil(maximum))]

func update_room(index: int) -> void:
	if room_label:
		if index == 7:
			room_label.text = "房間: 7 (BOSS 戰)"
		else:
			room_label.text = "房間: %d / 7" % index

func update_timer(remaining_sec: float) -> void:
	if timer_label:
		var mins := int(remaining_sec) / 60
		var secs := int(remaining_sec) % 60
		timer_label.text = "剩餘時間: %02d:%02d" % [mins, secs]

func show_doors(doors: Array[Dictionary]) -> void:
	current_doors = doors
	if door_panel and doors.size() >= 2:
		if door1_btn:
			door1_btn.text = "%s\n(危險: %s)" % [doors[0].label, "★".repeat(doors[0].danger)]
		if door2_btn:
			door2_btn.text = "%s\n(危險: %s)" % [doors[1].label, "★".repeat(doors[1].danger)]
		door_panel.show()

func hide_doors() -> void:
	if door_panel:
		door_panel.hide()

func show_message(msg: String, duration: float = 2.0) -> void:
	if message_label:
		message_label.text = msg
		if duration > 0.0:
			var tree := get_tree()
			if tree:
				await tree.create_timer(duration).timeout
				if is_instance_valid(message_label) and message_label.text == msg:
					message_label.text = ""

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		pause_requested.emit()
