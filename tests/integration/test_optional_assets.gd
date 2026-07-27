# tests/integration/test_optional_assets.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const AudioBusScript = preload("res://src/presentation/audio_bus.gd")
var test := TestCase.new()

func _initialize() -> void:
	var audio := AudioBusScript.new()
	test.check(not audio.play_path("res://assets/audio/not-present.wav"), "missing audio is safely ignored")
	test.check(audio.play_path("res://assets/audio/hit.wav"), "existing audio is accepted")
	audio.free()
	test.finish(self)
