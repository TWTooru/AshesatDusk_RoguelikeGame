# src/core/game_phase.gd
class_name GamePhase
extends RefCounted

enum Phase { TITLE, COMBAT, DOORS, UPGRADE, PAUSED, RESULTS }

static func can_transition(from: Phase, to: Phase) -> bool:
	var allowed := {
		Phase.TITLE: [Phase.COMBAT],
		Phase.COMBAT: [Phase.DOORS, Phase.UPGRADE, Phase.PAUSED, Phase.RESULTS],
		Phase.DOORS: [Phase.COMBAT, Phase.UPGRADE, Phase.RESULTS],
		Phase.UPGRADE: [Phase.COMBAT, Phase.DOORS, Phase.RESULTS],
		Phase.PAUSED: [Phase.COMBAT, Phase.RESULTS],
		Phase.RESULTS: [Phase.TITLE],
	}
	return to in allowed[from]
