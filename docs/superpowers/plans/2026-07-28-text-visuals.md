# Text-Based Visual Transformation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Transform all character, enemy, boss, weapon, and projectile drawings from geometric shapes into centered Chinese text labels using Godot's CanvasItem `draw_string()` while preserving existing hitboxes, physics, and gameplay logic.

**Architecture:** Update `_draw()` methods across entity scripts (`Player`, `Enemy` family, `Boss`, `Projectile`, `WeaponController`) to calculate horizontal and vertical text bounds, applying centered Chinese text with 1px dark drop-shadow and state-driven color highlights.

**Tech Stack:** Godot 4.7.1, GDScript 2.0, ThemeDB fallback fonts, Headless Godot test scripts (`tests/run_all.ps1`).

## Global Constraints

- The project must open and run with `C:\Users\user\Desktop\Godot_v4.7.1.exe`, version `4.7.1.stable.official.a13da4feb`.
- Player text must be `"玩家"`.
- Enemy texts: `"腐屍"` (zombie), `"骸骨弓手"` (archer), `"暗影蝙蝠"` (bat), `"墓園騎士"` (knight), `"無首守墓人"` (boss).
- Weapon/Projectile texts: `"幽魂彈"` (soul_bolt), `"骨刃環"` (bone_ring), `"冥火法陣"` (nether_flame), `"箭"` (enemy arrow), `"墓碑"` (tombstone).
- Collision shapes and physics movement must remain 100% untouched.
- All 11 test scripts in `tests/run_all.ps1` must pass cleanly without headless rendering errors.

---

### Task 1: Player Text Rendering

**Files:**
- Modify: `src/player/player.gd:83-97`
- Test: `tests/unit/test_player.gd`

**Interfaces:**
- Consumes: `ThemeDB.fallback_font`, `stats`, `invulnerability_left`, `facing_direction`.
- Produces: Centered `"玩家"` text rendering in `Player._draw()`.

- [ ] **Step 1: Write the failing unit test assertion for player text rendering state**

```gdscript
# Add to tests/unit/test_player.gd inside _initialize()
test.check(player.has_method("_draw"), "player has _draw method")
```

- [ ] **Step 2: Run test to verify it passes baseline**

Run: `& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_player.gd`
Expected: PASS

- [ ] **Step 3: Update `src/player/player.gd` `_draw()` to render `"玩家"` text**

```gdscript
func _draw() -> void:
	if dead:
		return
	var font := ThemeDB.fallback_font
	var text := "玩家"
	var font_size := 16
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(-text_size.x / 2.0, text_size.y / 4.0)

	var text_color := Color(1.0, 1.0, 1.0, 1.0) if invulnerability_left > 0.0 else Color(0.85, 0.95, 1.0, 1.0)
	var shadow_color := Color(0.0, 0.0, 0.0, 0.8)

	# Shadow
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, shadow_color)
	# Main Text
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

	# Gold facing rune dot indicator
	var rune_pos := facing_direction * 18.0
	draw_circle(rune_pos, 3.0, Color(0.95, 0.8, 0.2, 1.0))
```

- [ ] **Step 4: Run test to verify passes**

Run: `& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_player.gd`
Expected: PASS

- [ ] **Step 5: Commit**

```powershell
git add src/player/player.gd tests/unit/test_player.gd
git commit -m "feat: convert player visual to centered text label"
```

---

### Task 2: Regular Enemies Text Rendering

**Files:**
- Modify: `src/enemies/enemy.gd:70-86`
- Modify: `src/enemies/ranged_enemy.gd:47-50`
- Modify: `src/enemies/dash_enemy.gd:33-36`
- Test: `tests/unit/test_enemy_and_projectile.gd`

**Interfaces:**
- Consumes: `kind`, `ThemeDB.fallback_font`.
- Produces: Centered text labels (`腐屍`, `骸骨弓手`, `暗影蝙蝠`, `墓園騎士`) with telegraph lines.

- [ ] **Step 1: Update `src/enemies/enemy.gd` `_draw()` to render enemy Chinese labels**

```gdscript
func _draw() -> void:
	if dead:
		return
	var font := ThemeDB.fallback_font
	var text_map := {
		&"zombie": "腐屍",
		&"archer": "骸骨弓手",
		&"bat": "暗影蝙蝠",
		&"knight": "墓園騎士",
	}
	var color_map := {
		&"zombie": Color(0.4, 0.7, 0.45, 1.0),
		&"archer": Color(0.75, 0.7, 0.6, 1.0),
		&"bat": Color(0.7, 0.35, 0.8, 1.0),
		&"knight": Color(0.9, 0.8, 0.3, 1.0),
	}
	var text: String = text_map.get(kind, "怪物")
	var text_color: Color = color_map.get(kind, Color.WHITE)
	var font_size := 15
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(-text_size.x / 2.0, text_size.y / 4.0)

	# Shadow & Text
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.8))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
```

- [ ] **Step 2: Run unit test to verify clean execution**

Run: `& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_enemy_and_projectile.gd`
Expected: PASS

- [ ] **Step 3: Commit**

```powershell
git add src/enemies/enemy.gd src/enemies/ranged_enemy.gd src/enemies/dash_enemy.gd
git commit -m "feat: convert regular enemies visuals to centered text labels"
```

---

### Task 3: Gravekeeper Boss Text Rendering

**Files:**
- Modify: `src/enemies/boss.gd:164-188`
- Test: `tests/unit/test_boss.gd`

**Interfaces:**
- Consumes: Boss state, `max_health`, `current_health`, `tombstone_target_positions`, `charge_direction`.
- Produces: Large `"無首守墓人"` text label with health bar & telegraph overlays.

- [ ] **Step 1: Update `src/enemies/boss.gd` `_draw()` to render Boss label**

```gdscript
func _draw() -> void:
	if dead:
		return
	var font := ThemeDB.fallback_font
	var text := "無首守墓人"
	var font_size := 22
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(-text_size.x / 2.0, text_size.y / 4.0)

	# Boss Name Text
	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.9))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.95, 0.3, 0.4, 1.0))

	# Top Health bar
	var hp_ratio := current_health / max_health
	draw_rect(Rect2(-40, -28, 80, 6), Color(0.2, 0.2, 0.2, 0.8))
	draw_rect(Rect2(-40, -28, 80 * hp_ratio, 6), Color(0.85, 0.15, 0.15, 0.95))

	# Attack warnings
	if attack_state == &"telegraph_charge":
		draw_line(Vector2.ZERO, charge_direction * 300.0, Color(1.0, 0.1, 0.1, 0.7), 3.0)
	elif attack_state == &"telegraph_tombstones":
		for pos in tombstone_target_positions:
			var local_pos := to_local(pos)
			draw_circle(local_pos, 18.0, Color(1.0, 0.1, 0.1, 0.5))
	elif attack_state == &"telegraph_ring":
		draw_arc(Vector2.ZERO, 40.0, 0, TAU, 24, Color(1.0, 0.1, 0.1, 0.6), 2.0)
```

- [ ] **Step 2: Run boss unit test to verify clean execution**

Run: `& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_boss.gd`
Expected: PASS

- [ ] **Step 3: Commit**

```powershell
git add src/enemies/boss.gd
git commit -m "feat: convert boss visual to centered text label"
```

---

### Task 4: Weapons, Projectiles & Tombstones Text Rendering

**Files:**
- Modify: `src/combat/projectile.gd:57-61`
- Modify: `src/combat/weapon_controller.gd:188-204`
- Modify: `src/enemies/boss.gd:102-124` (tombstone rendering)
- Test: `tests/unit/test_weapon_controller.gd`

**Interfaces:**
- Consumes: `faction`, `weapon_levels`, `active_flames`.
- Produces: Text-rendered projectiles (`幽魂彈`, `箭`), orbiting text (`骨刃環`), ground flame text (`冥火法陣`), and obstacles (`墓碑`).

- [ ] **Step 1: Update `src/combat/projectile.gd` `_draw()` for text projectiles**

```gdscript
func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := "幽魂彈" if faction == &"player" else "箭"
	var text_color := Color(0.3, 0.85, 1.0) if faction == &"player" else Color(1.0, 0.3, 0.3)
	var font_size := 12
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_pos := Vector2(-text_size.x / 2.0, text_size.y / 4.0)

	draw_string(font, text_pos + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.8))
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
```

- [ ] **Step 2: Update `src/combat/weapon_controller.gd` `_draw()` for Bone Ring & Nether Flame text**

```gdscript
func _draw() -> void:
	var font := ThemeDB.fallback_font

	# Bone Ring text
	if weapon_levels.get(&"bone_ring", 0) > 0:
		var level := int(weapon_levels[&"bone_ring"])
		var blade_count: int = DEFINITIONS[&"bone_ring"].blades[level - 1]
		var radius := 54.0
		var text := "骨刃環"
		var font_size := 13
		var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_offset := Vector2(-text_size.x / 2.0, text_size.y / 4.0)

		for i in range(blade_count):
			var angle := bone_ring_angle + (i * TAU / blade_count)
			var b_pos := Vector2(cos(angle), sin(angle)) * radius
			draw_string(font, b_pos + text_offset + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0, 0, 0, 0.8))
			draw_string(font, b_pos + text_offset, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.95, 0.95, 0.85, 1.0))

	# Nether Flame text
	for flame in active_flames:
		var local_pos := to_local(flame.pos)
		if flame.warning_left > 0.0:
			draw_circle(local_pos, flame.radius, Color(0.6, 0.1, 0.7, 0.3))
		else:
			draw_circle(local_pos, flame.radius, Color(0.4, 0.0, 0.6, 0.35))
			var flame_text := "冥火法陣"
			var font_size := 14
			var text_size := font.get_string_size(flame_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_offset := Vector2(-text_size.x / 2.0, text_size.y / 4.0)
			draw_string(font, local_pos + text_offset, flame_text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(0.85, 0.4, 1.0, 0.9))
```

- [ ] **Step 3: Run weapon unit test to verify clean execution**

Run: `& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_weapon_controller.gd`
Expected: PASS

- [ ] **Step 4: Commit**

```powershell
git add src/combat/projectile.gd src/combat/weapon_controller.gd
git commit -m "feat: convert weapons and projectiles visuals to centered text labels"
```

---

### Task 5: Acceptance & Regression Verification

**Files:**
- Full repository

- [ ] **Step 1: Run complete test suite**

Run: `powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1`
Expected: ALL TESTS PASSED SUCCESSFULLY! Exit code 0.

- [ ] **Step 2: Final commit**

```powershell
git status --short
git commit -m "chore: complete text-based visual transformation"
```
