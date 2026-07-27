# src/upgrades/upgrade_catalog.gd
class_name UpgradeCatalog
extends RefCounted

const WEAPON_IDS: Array[StringName] = [&"soul_bolt", &"bone_ring", &"nether_flame"]
const PASSIVE_IDS: Array[StringName] = [&"move_speed", &"max_health", &"damage", &"attack_speed", &"damage_reduction", &"life_steal"]

static func _eligible_ids(stats: Dictionary, weapons: Dictionary) -> Array[StringName]:
	var list: Array[StringName] = []
	for wid in WEAPON_IDS:
		if int(weapons.get(wid, 0)) < 3:
			list.append(wid)
	if float(stats.get("move_speed", 260.0)) < 390.0:
		list.append(&"move_speed")
	list.append(&"max_health")
	list.append(&"damage")
	list.append(&"attack_speed")
	if float(stats.get("damage_reduction", 0.0)) < 0.45:
		list.append(&"damage_reduction")
	if float(stats.get("life_steal", 0.0)) < 0.08:
		list.append(&"life_steal")
	return list

static func choices(rng: RandomNumberGenerator, stats: Dictionary,
		weapons: Dictionary, count := 3) -> Array[StringName]:
	var eligible := _eligible_ids(stats, weapons)
	var result: Array[StringName] = []
	while result.size() < count and not eligible.is_empty():
		result.append(eligible.pop_at(rng.randi_range(0, eligible.size() - 1)))
	for fallback: StringName in [&"heal", &"fury"]:
		if result.size() == count:
			break
		if fallback not in result:
			result.append(fallback)
	return result

static func apply(id: StringName, stats: Dictionary, weapons: Dictionary) -> Dictionary:
	var next_stats := stats.duplicate(true)
	var next_weapons := weapons.duplicate(true)
	if id in WEAPON_IDS:
		next_weapons[id] = min(3, int(next_weapons.get(id, 0)) + 1)
	elif id == &"move_speed":
		next_stats.move_speed = minf(390.0, float(next_stats.move_speed) + 24.0)
	elif id == &"max_health":
		next_stats.max_health = float(next_stats.max_health) + 20.0
		next_stats.health = minf(float(next_stats.max_health), float(next_stats.health) + 20.0)
	elif id == &"damage":
		next_stats.damage_mult = float(next_stats.damage_mult) + 0.18
	elif id == &"attack_speed":
		next_stats.attack_speed_mult = float(next_stats.attack_speed_mult) + 0.15
	elif id == &"damage_reduction":
		next_stats.damage_reduction = minf(0.45, float(next_stats.damage_reduction) + 0.08)
	elif id == &"life_steal":
		next_stats.life_steal = minf(0.08, float(next_stats.life_steal) + 0.02)
	elif id == &"heal":
		next_stats.health = minf(float(next_stats.max_health), float(next_stats.health) + 30.0)
	elif id == &"fury":
		next_stats.attack_speed_mult = float(next_stats.attack_speed_mult) + 0.10
	return {"stats": next_stats, "weapons": next_weapons, "message": label_for(id)}

static func label_for(id: StringName) -> String:
	match id:
		&"soul_bolt": return "幽魂彈"
		&"bone_ring": return "骨刃環"
		&"nether_flame": return "冥火法陣"
		&"move_speed": return "疾風步伐 (+24 移速)"
		&"max_health": return "生命泉湧 (+20 生命上限)"
		&"damage": return "詛咒力量 (+18% 傷害)"
		&"attack_speed": return "狂暴狂熱 (+15% 攻速)"
		&"damage_reduction": return "暗影護甲 (+8% 減傷)"
		&"life_steal": return "靈魂汲取 (+2% 吸血)"
		&"heal": return "聖水療癒 (+35 生命)"
		&"fury": return "短暫狂熱 (+10% 攻速)"
		_: return String(id)
