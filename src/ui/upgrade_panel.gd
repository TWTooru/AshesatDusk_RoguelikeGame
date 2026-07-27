# src/ui/upgrade_panel.gd
class_name UpgradePanel
extends Control

signal upgrade_selected(id: StringName)

@onready var card1_btn: Button = $PanelContainer/Margin/VBox/CardsHBox/Card1
@onready var card2_btn: Button = $PanelContainer/Margin/VBox/CardsHBox/Card2
@onready var card3_btn: Button = $PanelContainer/Margin/VBox/CardsHBox/Card3

var current_choices: Array[StringName] = []

func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	card1_btn.pressed.connect(func(): _select(0))
	card2_btn.pressed.connect(func(): _select(1))
	card3_btn.pressed.connect(func(): _select(2))

func show_choices(choices: Array[StringName]) -> void:
	current_choices = choices
	var btns := [card1_btn, card2_btn, card3_btn]
	for i in range(3):
		if i < choices.size():
			var choice_id := choices[i]
			var label := UpgradeCatalog.label_for(choice_id)
			btns[i].text = "[%d] %s" % [i + 1, label]
			btns[i].show()
		else:
			btns[i].hide()
	show()

func _select(index: int) -> void:
	if index >= 0 and index < current_choices.size():
		var chosen_id := current_choices[index]
		hide()
		upgrade_selected.emit(chosen_id)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_code := event.keycode
		if key_code == KEY_1 or key_code == KEY_KP_1:
			_select(0)
			get_viewport().set_input_as_handled()
		elif key_code == KEY_2 or key_code == KEY_KP_2:
			_select(1)
			get_viewport().set_input_as_handled()
		elif key_code == KEY_3 or key_code == KEY_KP_3:
			_select(2)
			get_viewport().set_input_as_handled()
