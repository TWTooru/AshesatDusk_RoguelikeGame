# src/core/run_config.gd
class_name RunConfig
extends RefCounted

var room_count := 7
var time_limit_sec := 420.0
var seed_value := 0
var spawn_scale := 1.0
var is_demo := false

static func formal() -> RunConfig:
	var value := RunConfig.new()
	value.room_count = 7
	value.time_limit_sec = 420.0
	value.seed_value = int(Time.get_unix_time_from_system())
	return value

static func demo() -> RunConfig:
	var value := RunConfig.new()
	value.room_count = 4
	value.time_limit_sec = 60.0
	value.seed_value = 4701
	value.spawn_scale = 0.28
	value.is_demo = true
	return value
