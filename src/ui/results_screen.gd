# src/ui/results_screen.gd
class_name ResultsScreen
extends CanvasLayer

signal retry_requested
signal title_requested

@onready var outcome_label: Label = $Root/PanelContainer/Margin/VBox/OutcomeLabel
@onready var stats_label: Label = $Root/PanelContainer/Margin/VBox/StatsLabel
@onready var retry_btn: Button = $Root/PanelContainer/Margin/VBox/ButtonsHBox/RetryButton
@onready var title_btn: Button = $Root/PanelContainer/Margin/VBox/ButtonsHBox/TitleButton

func _ready() -> void:
	layer = 70
	process_mode = PROCESS_MODE_ALWAYS
	if retry_btn:
		retry_btn.text = CopyZhTw.BTN_RETRY
		retry_btn.pressed.connect(func(): retry_requested.emit())
	if title_btn:
		title_btn.text = CopyZhTw.BTN_RETURN_TITLE
		title_btn.pressed.connect(func(): title_requested.emit())

func show_results(summary: Dictionary) -> void:
	var outcome: StringName = summary.get("outcome", &"death")
	if outcome_label:
		match outcome:
			&"victory":
				outcome_label.text = CopyZhTw.OUTCOME_VICTORY
				outcome_label.add_theme_color_override("font_color", Color(0.3, 0.9, 0.4, 1.0))
			&"timeout":
				outcome_label.text = CopyZhTw.OUTCOME_TIMEOUT
				outcome_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.2, 1.0))
			_:
				outcome_label.text = CopyZhTw.OUTCOME_DEATH
				outcome_label.add_theme_color_override("font_color", Color(0.9, 0.2, 0.2, 1.0))

	var elapsed: float = float(summary.get("elapsed_sec", 0.0))
	var mins := int(elapsed) / 60
	var secs := int(elapsed) % 60
	var kills: int = int(summary.get("kills", 0))
	var rooms: int = int(summary.get("rooms_cleared", 0))
	
	var weapons: Dictionary = summary.get("weapons", {})
	var weapon_str := ""
	for w_id in weapons:
		var name_str := UpgradeCatalog.label_for(w_id)
		weapon_str += "%s Lv.%d  " % [name_str, weapons[w_id]]
		
	if stats_label:
		stats_label.text = "存活時間: %02d:%02d\n擊殺數量: %d\n通過房間: %d / 7\n最終武器: %s" % [mins, secs, kills, rooms, weapon_str]
	show()
