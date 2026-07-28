# src/ui/title_screen.gd
class_name TitleScreen
extends Control

signal formal_start_requested
signal demo_start_requested

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var formal_btn: Button = $VBox/FormalButton
@onready var demo_btn: Button = $VBox/DemoButton

func _ready() -> void:
	if title_label:
		title_label.text = CopyZhTw.GAME_TITLE
	if subtitle_label:
		subtitle_label.text = CopyZhTw.GAME_SUBTITLE
	if formal_btn:
		formal_btn.text = CopyZhTw.BTN_FORMAL_MODE
		formal_btn.pressed.connect(func(): formal_start_requested.emit())
	if demo_btn:
		demo_btn.text = CopyZhTw.BTN_DEMO_MODE
		demo_btn.pressed.connect(func(): demo_start_requested.emit())
