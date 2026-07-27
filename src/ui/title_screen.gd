# src/ui/title_screen.gd
class_name TitleScreen
extends Control

signal formal_start_requested
signal demo_start_requested

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var formal_btn: Button = $VBox/FormalButton
@onready var demo_btn: Button = $VBox/DemoButton
@onready var title_art: TextureRect = $TitleArt

func _ready() -> void:
	if ResourceLoader.exists("res://assets/generated/title_art.png"):
		title_art.texture = load("res://assets/generated/title_art.png") as Texture2D
	
	title_label.text = CopyZhTw.GAME_TITLE
	subtitle_label.text = CopyZhTw.GAME_SUBTITLE
	formal_btn.text = CopyZhTw.BTN_FORMAL_MODE
	demo_btn.text = CopyZhTw.BTN_DEMO_MODE
	
	formal_btn.pressed.connect(func(): formal_start_requested.emit())
	demo_btn.pressed.connect(func(): demo_start_requested.emit())
