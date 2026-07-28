# src/rooms/room_planner.gd
class_name RoomPlanner
extends RefCounted

const FORMAL_COUNTS := {
	1: {&"zombie": 10},
	2: {&"zombie": 12, &"archer": 3},
	3: {&"zombie": 12, &"archer": 4, &"bat": 5},
	4: {&"zombie": 14, &"archer": 5, &"bat": 6, &"knight": 1},
	5: {&"zombie": 16, &"archer": 6, &"bat": 8, &"knight": 1},
	6: {&"zombie": 18, &"archer": 7, &"bat": 10, &"knight": 2},
}

static func plan(index: int, cursed: bool, config: RunConfig) -> RoomPlan:
	if index == 7:
		return RoomPlan.new(index, 1.6, {}, cursed, true)
	
	var base_counts: Dictionary = FORMAL_COUNTS.get(index, FORMAL_COUNTS[1]).duplicate()
	var counts := {}
	
	for kind in base_counts:
		var c: int = int(base_counts[kind])
		if c > 0:
			if config.is_demo:
				counts[kind] = maxi(1, roundi(c * config.spawn_scale))
			else:
				counts[kind] = c
				
	if cursed:
		for kind in counts:
			if kind != &"knight":
				counts[kind] = ceili(int(counts[kind]) * 1.35)
		counts[&"knight"] = int(counts.get(&"knight", 0)) + 1
		
	return RoomPlan.new(index, 1.0 + index * 0.1, counts, cursed, false)

static func door_choices(index: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var types: Array[StringName] = [&"weapon", &"ability", &"heal", &"curse"]
	var first: StringName = types.pop_at(rng.randi_range(0, types.size() - 1))
	var second: StringName = types.pop_at(rng.randi_range(0, types.size() - 1))
	if index == 6 and first != &"curse" and second != &"curse":
		second = &"curse"
	return [_door(first, index), _door(second, index)]


static func _door(type: StringName, index: int) -> Dictionary:
	match type:
		&"weapon":
			return {"type": &"weapon", "label": "武器祭壇", "danger": clampi(1 + index / 3, 1, 3), "cursed": false, "upgrade_count": 1}
		&"ability":
			return {"type": &"ability", "label": "禁忌能力", "danger": clampi(1 + index / 3, 1, 3), "cursed": false, "upgrade_count": 1}
		&"heal":
			return {"type": &"heal", "label": "療癒聖泉", "danger": clampi(1 + index / 4, 1, 2), "cursed": false, "upgrade_count": 0}
		&"curse":
			return {"type": &"curse", "label": "詛咒寶箱", "danger": 3, "cursed": true, "upgrade_count": 2}
		_:
			return {"type": type, "label": String(type), "danger": 1, "cursed": false, "upgrade_count": 1}
