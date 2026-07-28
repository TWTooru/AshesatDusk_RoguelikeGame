# src/presentation/audio_bus.gd
class_name AudioBus
extends Node

const SFX_PATHS := {
	&"hit": "res://assets/audio/hit.wav",
	&"hurt": "res://assets/audio/hurt.wav",
	&"upgrade": "res://assets/audio/upgrade.wav",
	&"door": "res://assets/audio/door.wav",
	&"boss_warning": "res://assets/audio/boss_warning.wav",
}

var bgm_player: AudioStreamPlayer

func _ready() -> void:
	bgm_player = AudioStreamPlayer.new()
	add_child(bgm_player)
	if ResourceLoader.exists("res://assets/audio/ambience.wav"):
		bgm_player.stream = load("res://assets/audio/ambience.wav")
		bgm_player.volume_db = -12.0

func play_sfx(id: StringName) -> bool:
	return false if id not in SFX_PATHS else play_path(SFX_PATHS[id])

func play_path(path: String) -> bool:
	if not ResourceLoader.exists(path) or not is_inside_tree():
		return false
	var player := AudioStreamPlayer.new()
	add_child(player)
	player.stream = load(path)
	player.finished.connect(player.queue_free)
	player.play()
	return true

func play_ambience() -> void:
	if bgm_player and bgm_player.stream and not bgm_player.playing and is_inside_tree():
		bgm_player.play()

func stop_ambience() -> void:
	if bgm_player and bgm_player.playing:
		bgm_player.stop()
