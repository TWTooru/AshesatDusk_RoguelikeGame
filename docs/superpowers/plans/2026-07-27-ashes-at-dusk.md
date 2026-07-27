# Ashes at Dusk Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete Godot 4.7.1 Windows-ready seven-minute room-based dark-fantasy Roguelike with movement-only controls, automatic weapons, route choices, upgrades, a final boss, and a deterministic recording mode.

**Architecture:** Use small Godot scenes whose scripts own one responsibility, with pure domain helpers for run configuration, upgrade selection, room planning, and targeting. `GameController` is the only run-state coordinator; gameplay systems publish signals and never reach into HUD internals. Characters and effects use code-drawn pixel-style visuals so collision silhouettes remain exact, while optional AI-generated art is isolated to presentation backgrounds.

**Tech Stack:** Godot 4.7.1, GDScript 2.0, Godot built-in scenes/resources/signals, headless Godot test scripts, PNG/WAV assets, Markdown documentation.

## Global Constraints

- The project must open and run with `C:\Users\user\Desktop\Godot_v4.7.1.exe`, version `4.7.1.stable.official.a13da4feb`.
- The target platform is Windows desktop; the base viewport is 1280×720 and must scale cleanly to 1920×1080.
- Formal mode contains six normal rooms plus room seven as the Boss room, with a 420-second hard limit.
- Controls are WASD or arrow keys for movement, `Esc` for pause/back, and mouse or `1`/`2`/`3` for upgrades.
- Attacks are automatic; there is no aiming or attack button.
- Player-visible text is Traditional Chinese.
- Runtime dependencies and third-party Godot add-ons are not allowed.
- The MP4 file is not a deliverable; recording mode, storyboard, and subtitle copy are deliverables.
- Keep optional bitmap/audio failures non-fatal by providing code-drawn visuals and silent-safe gameplay.

---

## File Map

### Project and shared domain

- `project.godot` — project metadata, input actions, viewport, boot scene.
- `src/core/game_phase.gd` — legal run phases and guarded transitions.
- `src/core/run_config.gd` — formal/demo timing, room counts, seeds, and spawn multipliers.
- `src/core/game_controller.gd` — run timer, room progression, pause, victory/failure, restart.
- `src/core/copy_zh_tw.gd` — stable player-visible Traditional Chinese strings.
- `tests/support/test_case.gd` — dependency-free assertion helper.

### Gameplay

- `src/player/player.gd` and `scenes/player/player.tscn` — input, movement, health, invulnerability, player drawing.
- `src/enemies/enemy.gd` and `scenes/enemies/enemy.tscn` — shared enemy health, pursuit, contact damage, drawing.
- `src/enemies/ranged_enemy.gd` — archer spacing and warned shot.
- `src/enemies/dash_enemy.gd` — bat telegraph and dash.
- `src/enemies/boss.gd` and `scenes/enemies/boss.tscn` — headless gravekeeper state machine.
- `src/combat/projectile.gd` and `scenes/combat/projectile.tscn` — reusable player/enemy projectile.
- `src/combat/weapon_controller.gd` — target selection, cooldowns, weapon inventory, weapon effects.
- `src/upgrades/upgrade_catalog.gd` — definitions, eligibility, deterministic three-choice selection, application.
- `src/rooms/room_plan.gd` — typed room plan value object.
- `src/rooms/room_planner.gd` — wave composition and two distinct door rewards.
- `src/rooms/room_manager.gd` — spawning, cleanup, room-clear detection, exits, reward application.

### Presentation

- `src/ui/hud.gd` and `scenes/ui/hud.tscn` — health, timer, room, pause, door and warning messages.
- `src/ui/title_screen.gd` and `scenes/ui/title_screen.tscn` — formal/demo start and instructions.
- `src/ui/upgrade_panel.gd` and `scenes/ui/upgrade_panel.tscn` — paused three-card selection.
- `src/ui/results_screen.gd` and `scenes/ui/results_screen.tscn` — victory/failure statistics and restart.
- `src/presentation/graveyard_backdrop.gd` — code-drawn fallback floor, borders, obstacles, ambient particles.
- `src/presentation/audio_bus.gd` — safe optional sound loading and playback.
- `scenes/main.tscn` — composition root.
- `assets/generated/graveyard_background.png` — optional AI-assisted background.
- `assets/generated/title_art.png` — optional AI-assisted title image.
- `assets/audio/*.wav` — short original or generated sound effects.

### Documentation and verification

- `README.md` — setup, controls, run modes, export, structure.
- `docs/game-report.md` — game introduction, market rationale, tools, AI usage, development process.
- `docs/recording-guide.md` — exact one-minute shot list and Traditional Chinese subtitle copy.
- `tests/unit/*.gd` — pure/domain and component tests.
- `tests/integration/test_main_scene.gd` — boot/smoke/run-state integration.
- `tests/run_all.ps1` — sequential headless test command with non-zero failure propagation.

---

### Task 1: Runnable Godot Shell and Native Test Harness

**Files:**
- Create: `project.godot`
- Create: `scenes/main.tscn`
- Create: `src/presentation/graveyard_backdrop.gd`
- Create: `tests/support/test_case.gd`
- Create: `tests/integration/test_project_boot.gd`

**Interfaces:**
- Consumes: none.
- Produces: `TestCase.check(condition: bool, message: String)`, `TestCase.equal(actual: Variant, expected: Variant, message: String)`, `TestCase.finish(tree: SceneTree)`, and a loadable `res://scenes/main.tscn`.

- [ ] **Step 1: Write the failing project boot test**

```gdscript
# tests/integration/test_project_boot.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
var test := TestCase.new()

func _initialize() -> void:
    var packed := load("res://scenes/main.tscn") as PackedScene
    test.check(packed != null, "main scene must load")
    if packed:
        var main := packed.instantiate()
        test.equal(main.name, "Main", "composition root name")
        test.check(main.has_node("Backdrop"), "main has fallback backdrop")
        main.free()
    test.finish(self)
```

- [ ] **Step 2: Run the test and verify it fails**

Run:

```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/integration/test_project_boot.gd
```

Expected: non-zero exit because `project.godot`, test support, or `main.tscn` does not exist.

- [ ] **Step 3: Add the project, assertion helper, fallback backdrop, and composition root**

Use this assertion API:

```gdscript
# tests/support/test_case.gd
class_name TestCase
extends RefCounted

var failures := 0

func check(condition: bool, message: String) -> void:
    if not condition:
        failures += 1
        push_error(message)

func equal(actual: Variant, expected: Variant, message: String) -> void:
    check(actual == expected, "%s: expected %s, got %s" % [message, expected, actual])

func finish(tree: SceneTree) -> void:
    tree.quit(1 if failures > 0 else 0)
```

Configure `project.godot` with `run/main_scene="res://scenes/main.tscn"`, 1280×720 canvas-items stretch, and input actions for `move_left`, `move_right`, `move_up`, `move_down`, and `pause`. Make `graveyard_backdrop.gd` extend `Node2D`, draw a dark floor, 16-pixel grid, gold exit accents, and a 32-pixel play-area border from `Rect2(32, 96, 1216, 592)`. Create `main.tscn` with `Main` and child `Backdrop`.

```ini
; project.godot core settings
[application]
run/main_scene="res://scenes/main.tscn"

[display]
window/size/viewport_width=1280
window/size/viewport_height=720
window/stretch/mode="canvas_items"
```

- [ ] **Step 4: Re-run the test and open the project headlessly**

Run:

```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/integration/test_project_boot.gd
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --editor --quit
```

Expected: both commands exit `0` without parser, missing-resource, or UID errors.

- [ ] **Step 5: Commit**

```powershell
git add project.godot scenes/main.tscn src/presentation/graveyard_backdrop.gd tests/support/test_case.gd tests/integration/test_project_boot.gd
git commit -m "chore: scaffold Godot project and native tests"
```

---

### Task 2: Run Phases and Formal/Demo Configuration

**Files:**
- Create: `src/core/game_phase.gd`
- Create: `src/core/run_config.gd`
- Create: `tests/unit/test_run_domain.gd`

**Interfaces:**
- Consumes: `TestCase`.
- Produces: `GamePhase.Phase`, `GamePhase.can_transition(from, to) -> bool`, `RunConfig.formal() -> RunConfig`, `RunConfig.demo() -> RunConfig`, and fields `room_count`, `time_limit_sec`, `seed_value`, `spawn_scale`, `is_demo`.

- [ ] **Step 1: Write failing phase/config tests**

```gdscript
# tests/unit/test_run_domain.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const GamePhase = preload("res://src/core/game_phase.gd")
const RunConfig = preload("res://src/core/run_config.gd")
var test := TestCase.new()

func _initialize() -> void:
    test.check(GamePhase.can_transition(GamePhase.Phase.TITLE, GamePhase.Phase.COMBAT), "title starts combat")
    test.check(not GamePhase.can_transition(GamePhase.Phase.RESULTS, GamePhase.Phase.COMBAT), "results must restart through title")
    var formal := RunConfig.formal()
    test.equal(formal.room_count, 7, "formal room count")
    test.equal(formal.time_limit_sec, 420.0, "formal time limit")
    test.check(not formal.is_demo, "formal flag")
    var demo := RunConfig.demo()
    test.equal(demo.room_count, 7, "demo still demonstrates seven rooms")
    test.equal(demo.seed_value, 4701, "demo deterministic seed")
    test.check(demo.spawn_scale < 1.0 and demo.is_demo, "demo is accelerated")
    test.finish(self)
```

- [ ] **Step 2: Run the test and verify the missing-script failure**

Run:

```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_run_domain.gd
```

Expected: non-zero exit because `game_phase.gd` and `run_config.gd` do not exist.

- [ ] **Step 3: Implement explicit phases and immutable-style factories**

```gdscript
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
```

```gdscript
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
    value.seed_value = int(Time.get_unix_time_from_system())
    return value

static func demo() -> RunConfig:
    var value := RunConfig.new()
    value.time_limit_sec = 75.0
    value.seed_value = 4701
    value.spawn_scale = 0.28
    value.is_demo = true
    return value
```

- [ ] **Step 4: Run the test**

Expected: exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/core/game_phase.gd src/core/run_config.gd tests/unit/test_run_domain.gd
git commit -m "feat: define run phases and formal demo configs"
```

---

### Task 3: Deterministic Upgrade Catalog

**Files:**
- Create: `src/upgrades/upgrade_catalog.gd`
- Create: `tests/unit/test_upgrade_catalog.gd`

**Interfaces:**
- Consumes: player stats dictionary and weapon levels dictionary.
- Produces: `UpgradeCatalog.choices(rng, stats, weapon_levels, count := 3) -> Array[StringName]`, `UpgradeCatalog.apply(id, stats, weapon_levels) -> Dictionary`, `UpgradeCatalog.label_for(id) -> String`.
- Return shape from `apply`: `{"stats": Dictionary, "weapons": Dictionary, "message": String}`.

- [ ] **Step 1: Write failing eligibility and application tests**

```gdscript
# tests/unit/test_upgrade_catalog.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Catalog = preload("res://src/upgrades/upgrade_catalog.gd")
var test := TestCase.new()

func _initialize() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 4701
    var stats := {"max_health": 100.0, "health": 40.0, "move_speed": 260.0,
        "damage_mult": 1.0, "attack_speed_mult": 1.0, "damage_reduction": 0.0, "life_steal": 0.0}
    var weapons := {&"soul_bolt": 3, &"bone_ring": 3, &"nether_flame": 3}
    var picks := Catalog.choices(rng, stats, weapons, 3)
    test.equal(picks.size(), 3, "always fills three cards")
    var unique := {}
    for pick in picks:
        unique[pick] = true
    test.equal(unique.size(), 3, "cards are unique")
    test.check(&"soul_bolt" not in picks, "max weapon is excluded")
    var result := Catalog.apply(&"max_health", stats, weapons)
    test.equal(result.stats.max_health, 120.0, "health cap increases by twenty")
    test.equal(result.stats.health, 60.0, "increase also heals twenty")
    test.finish(self)
```

- [ ] **Step 2: Run and verify failure**

Expected: non-zero exit because the catalog is missing.

- [ ] **Step 3: Implement the fixed catalog and fallback rewards**

Define weapon IDs `soul_bolt`, `bone_ring`, `nether_flame`; passive IDs `move_speed`, `max_health`, `damage`, `attack_speed`, `damage_reduction`, `life_steal`; fallbacks `heal` and `fury`. Exclude weapon IDs at level three, cap move speed at 390, damage reduction at 0.45, and life steal at 0.08. Shuffle eligible IDs with the supplied RNG only. If fewer than three are eligible, append distinct fallbacks.

Application increments a weapon by one; otherwise apply these exact values: speed `+24`, max health and current health `+20`, damage multiplier `+0.18`, attack-speed multiplier `+0.15`, reduction `+0.08`, life steal `+0.02`, heal `+30` capped at max, fury attack-speed multiplier `+0.10`. Copy incoming dictionaries before mutation.

```gdscript
static func choices(rng: RandomNumberGenerator, stats: Dictionary,
        weapons: Dictionary, count := 3) -> Array[StringName]:
    var eligible: Array[StringName] = _eligible_ids(stats, weapons)
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
    if id in [&"soul_bolt", &"bone_ring", &"nether_flame"]:
        next_weapons[id] = min(3, int(next_weapons.get(id, 0)) + 1)
    elif id == &"move_speed":
        next_stats.move_speed = minf(390.0, next_stats.move_speed + 24.0)
    elif id == &"max_health":
        next_stats.max_health += 20.0
        next_stats.health = min(next_stats.max_health, next_stats.health + 20.0)
    elif id == &"damage":
        next_stats.damage_mult += 0.18
    elif id == &"attack_speed":
        next_stats.attack_speed_mult += 0.15
    elif id == &"damage_reduction":
        next_stats.damage_reduction = minf(0.45, next_stats.damage_reduction + 0.08)
    elif id == &"life_steal":
        next_stats.life_steal = minf(0.08, next_stats.life_steal + 0.02)
    elif id == &"heal":
        next_stats.health = minf(next_stats.max_health, next_stats.health + 30.0)
    elif id == &"fury":
        next_stats.attack_speed_mult += 0.10
    return {"stats": next_stats, "weapons": next_weapons, "message": label_for(id)}
```

- [ ] **Step 4: Run the focused test**

Run:

```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_upgrade_catalog.gd
```

Expected: exit `0`; no duplicate or capped weapon choices.

- [ ] **Step 5: Commit**

```powershell
git add src/upgrades/upgrade_catalog.gd tests/unit/test_upgrade_catalog.gd
git commit -m "feat: add deterministic upgrade catalog"
```

---

### Task 4: Player Movement, Health, and Damage Safety

**Files:**
- Create: `src/player/player.gd`
- Create: `scenes/player/player.tscn`
- Create: `tests/unit/test_player.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: input actions from `project.godot`.
- Produces: signals `health_changed(current: float, maximum: float)`, `died`; methods `reset_for_run(stats: Dictionary)`, `take_damage(amount: float) -> bool`, `heal(amount: float)`, `set_control_enabled(value: bool)`, `get_stats() -> Dictionary`.

- [ ] **Step 1: Write failing health tests**

```gdscript
# tests/unit/test_player.gd
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Player = preload("res://src/player/player.gd")
var test := TestCase.new()

func _initialize() -> void:
    var player := Player.new()
    player.reset_for_run({"max_health": 100.0, "health": 100.0, "move_speed": 260.0,
        "damage_reduction": 0.25, "damage_mult": 1.0, "attack_speed_mult": 1.0, "life_steal": 0.0})
    test.check(player.take_damage(40.0), "first hit applies")
    test.equal(player.get_stats().health, 70.0, "reduction applies")
    test.check(not player.take_damage(40.0), "invulnerability blocks immediate repeat")
    player.set_invulnerability_for_test(0.0)
    player.heal(999.0)
    test.equal(player.get_stats().health, 100.0, "healing clamps")
    player.free()
    test.finish(self)
```

- [ ] **Step 2: Run and verify the missing-player failure**

- [ ] **Step 3: Implement the component and scene**

Make `Player` extend `CharacterBody2D`. Normalize combined input before multiplying by `move_speed`; use `move_and_slide`; clamp global position to `Rect2(48, 112, 1184, 560)`. `take_damage` returns `false` while `invulnerability_left > 0`, otherwise applies `max(1.0, amount * (1.0 - damage_reduction))`, sets 0.6 seconds invulnerability, emits health, and emits `died` exactly once at zero. Draw a 16×20 hooded hunter with a gold facing rune and flash white during invulnerability. Add a 16-pixel collision capsule.

Expose `set_invulnerability_for_test(value)` as a narrow deterministic seam; production updates the same field in `_physics_process`.

```gdscript
func _physics_process(delta: float) -> void:
    invulnerability_left = maxf(0.0, invulnerability_left - delta)
    if control_enabled:
        var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
        velocity = input_vector * float(stats.move_speed)
        move_and_slide()
        global_position = global_position.clamp(PLAY_BOUNDS.position, PLAY_BOUNDS.end)
    else:
        velocity = Vector2.ZERO

func take_damage(amount: float) -> bool:
    if invulnerability_left > 0.0 or dead:
        return false
    stats.health = maxf(0.0, stats.health - maxf(1.0, amount * (1.0 - stats.damage_reduction)))
    invulnerability_left = 0.6
    health_changed.emit(stats.health, stats.max_health)
    if stats.health <= 0.0:
        dead = true
        died.emit()
    return true
```

- [ ] **Step 4: Run the player test and main boot test**

Run both headless scripts. Expected: exit `0`, and `main.tscn` contains a `Player` child at `(640, 400)`.

- [ ] **Step 5: Commit**

```powershell
git add src/player/player.gd scenes/player/player.tscn scenes/main.tscn tests/unit/test_player.gd
git commit -m "feat: add bounded player movement and health"
```

---

### Task 5: Enemy Family and Reusable Projectiles

**Files:**
- Create: `src/enemies/enemy.gd`
- Create: `src/enemies/ranged_enemy.gd`
- Create: `src/enemies/dash_enemy.gd`
- Create: `src/combat/projectile.gd`
- Create: `scenes/enemies/enemy.tscn`
- Create: `scenes/combat/projectile.tscn`
- Create: `tests/unit/test_enemy_and_projectile.gd`

**Interfaces:**
- Consumes: a target `Node2D` with `take_damage(float)`.
- Produces: `Enemy.configure(kind: StringName, difficulty: float, target: Node2D)`, `Enemy.take_damage(amount: float, source: Node = null) -> bool`, signal `died(enemy: Node, kind: StringName)`, and `Projectile.launch(direction, speed, damage, faction, lifetime)`.

- [ ] **Step 1: Write failing enemy scaling and projectile tests**

```gdscript
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Enemy = preload("res://src/enemies/enemy.gd")
const Projectile = preload("res://src/combat/projectile.gd")
var test := TestCase.new()

func _initialize() -> void:
    var enemy := Enemy.new()
    enemy.configure(&"zombie", 1.5, null)
    test.equal(enemy.max_health, 45.0, "zombie base 30 scaled by difficulty")
    test.check(not enemy.take_damage(44.0), "nonlethal hit reports false")
    test.check(enemy.take_damage(1.0), "lethal hit reports true")
    var shot := Projectile.new()
    shot.launch(Vector2.RIGHT, 500.0, 12.0, &"player", 2.0)
    test.equal(shot.velocity, Vector2(500.0, 0.0), "launch velocity")
    test.equal(shot.damage, 12.0, "launch damage")
    enemy.free()
    shot.free()
    test.finish(self)
```

- [ ] **Step 2: Run and verify failure**

- [ ] **Step 3: Implement exact enemy profiles and specializations**

Profiles:

| ID | HP | Speed | Contact |
|---|---:|---:|---:|
| `zombie` | 30 | 65 | 10 |
| `archer` | 24 | 78 | 8 |
| `bat` | 18 | 105 | 9 |
| `knight` | 110 | 48 | 18 |

Multiply HP and contact damage by `difficulty`; multiply speed by `min(1.35, 0.9 + difficulty * 0.1)`. Base enemies pursue the target and use a 0.8-second contact cooldown. `RangedEnemy` maintains 240–330 pixels and fires a red-warning arrow every 2.2 seconds. `DashEnemy` pauses for a 0.45-second red telegraph, then dashes 220 pixels at 420 pixels/second. Draw each kind with a distinct silhouette and color.

`Projectile` uses faction-specific collision masks, moves by velocity, expires at lifetime, damages once, and frees itself. Enemy death emits once and does not queue a second reward.

```gdscript
# enemy.gd essential behavior
func configure(kind_id: StringName, difficulty: float, new_target: Node2D) -> void:
    kind = kind_id
    target = new_target
    var profile: Dictionary = PROFILES[kind]
    max_health = float(profile.hp) * difficulty
    current_health = max_health
    move_speed = float(profile.speed) * minf(1.35, 0.9 + difficulty * 0.1)
    contact_damage = float(profile.contact) * difficulty

func take_damage(amount: float, _source: Node = null) -> bool:
    if dead:
        return false
    current_health = maxf(0.0, current_health - amount)
    if current_health > 0.0:
        return false
    dead = true
    died.emit(self, kind)
    queue_free()
    return true
```

```gdscript
# projectile.gd essential behavior
func launch(direction: Vector2, speed: float, value: float,
        owner_faction: StringName, seconds: float) -> void:
    velocity = direction.normalized() * speed
    damage = value
    faction = owner_faction
    lifetime_left = seconds

func _physics_process(delta: float) -> void:
    position += velocity * delta
    lifetime_left -= delta
    if lifetime_left <= 0.0:
        queue_free()
```

- [ ] **Step 4: Run the unit test and parser check**

Run:

```powershell
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --script res://tests/unit/test_enemy_and_projectile.gd
& 'C:\Users\user\Desktop\Godot_v4.7.1.exe' --headless --path . --editor --quit
```

Expected: both exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/enemies src/combat/projectile.gd scenes/enemies/enemy.tscn scenes/combat/projectile.tscn tests/unit/test_enemy_and_projectile.gd
git commit -m "feat: add enemy family and projectiles"
```

---

### Task 6: Automatic Three-Weapon Combat

**Files:**
- Create: `src/combat/weapon_controller.gd`
- Create: `tests/unit/test_weapon_controller.gd`
- Modify: `scenes/player/player.tscn`

**Interfaces:**
- Consumes: player stat multipliers, weapon level dictionary, nodes in group `enemies`.
- Produces: `set_loadout(levels: Dictionary, stats: Dictionary)`, `nearest_target(origin, candidates) -> Node2D`, `damage_dealt(amount: float)` signal, and implementations for `soul_bolt`, `bone_ring`, `nether_flame`.

- [ ] **Step 1: Write failing nearest-target and cooldown tests**

```gdscript
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Weapons = preload("res://src/combat/weapon_controller.gd")
var test := TestCase.new()

func _initialize() -> void:
    var controller := Weapons.new()
    var far := Node2D.new()
    far.position = Vector2(90, 0)
    var near := Node2D.new()
    near.position = Vector2(20, 0)
    test.equal(controller.nearest_target(Vector2.ZERO, [far, near]), near, "nearest valid target")
    controller.set_loadout({&"soul_bolt": 2}, {"damage_mult": 1.5, "attack_speed_mult": 2.0})
    test.equal(controller.weapon_damage(&"soul_bolt"), 27.0, "level two damage times multiplier")
    test.equal(controller.weapon_cooldown(&"soul_bolt"), 0.4, "cooldown divided by attack speed")
    far.free()
    near.free()
    controller.free()
    test.finish(self)
```

- [ ] **Step 2: Run and verify failure**

- [ ] **Step 3: Implement weapon definitions and effects**

Use exact definitions:

- Soul bolt level damage `[12, 18, 26]`, base cooldown `0.8`, projectile counts `[1, 1, 2]`.
- Bone ring level damage `[8, 12, 17]`, blade counts `[2, 3, 4]`, rotation speed `2.4`.
- Nether flame level damage `[16, 24, 34]`, base cooldown `2.8`, radius `[56, 72, 92]`, duration `1.5`.

Only soul bolt requires a target. Bone blades are `Area2D` children that damage each enemy no more than once per 0.45 seconds. Nether flame chooses the densest enemy cluster from up to eight candidates and shows a purple warning for 0.3 seconds before damage. Apply life steal through `damage_dealt`, capped to one heal event per rendered frame.

```gdscript
func nearest_target(origin: Vector2, candidates: Array) -> Node2D:
    var best: Node2D
    var best_distance := INF
    for candidate: Node2D in candidates:
        if not is_instance_valid(candidate):
            continue
        var distance := origin.distance_squared_to(candidate.global_position)
        if distance < best_distance:
            best = candidate
            best_distance = distance
    return best

func weapon_damage(id: StringName) -> float:
    var level := int(weapon_levels.get(id, 0))
    return float(DEFINITIONS[id].damage[level - 1]) * float(stats.damage_mult)

func weapon_cooldown(id: StringName) -> float:
    return float(DEFINITIONS[id].cooldown) / float(stats.attack_speed_mult)
```

- [ ] **Step 4: Run unit tests and a 180-frame headless combat smoke**

Add a test loop that spawns two enemies, advances weapon `_process` with `1.0 / 60.0`, and asserts at least one enemy loses health without attack input. Expected: exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/combat/weapon_controller.gd scenes/player/player.tscn tests/unit/test_weapon_controller.gd
git commit -m "feat: add automatic weapon loadout"
```

---

### Task 7: Room Plans, Enemy Waves, and Risk/Reward Doors

**Files:**
- Create: `src/rooms/room_plan.gd`
- Create: `src/rooms/room_planner.gd`
- Create: `src/rooms/room_manager.gd`
- Create: `tests/unit/test_room_planner.gd`
- Create: `tests/integration/test_room_manager.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: `RunConfig`, enemy scene, player, RNG, and `UpgradeCatalog`.
- Produces: `RoomPlan(room_index, difficulty, enemy_counts, cursed, boss)`, `RoomPlanner.plan(index, cursed, config)`, `RoomPlanner.door_choices(index, rng) -> Array[Dictionary]`, signals `room_cleared`, `door_selected(reward: Dictionary)`, `enemy_killed(kind)`, methods `start_room(plan)`, `cleanup_room()`.

- [ ] **Step 1: Write failing deterministic plan tests**

```gdscript
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Planner = preload("res://src/rooms/room_planner.gd")
const RunConfig = preload("res://src/core/run_config.gd")
var test := TestCase.new()

func _initialize() -> void:
    var rng := RandomNumberGenerator.new()
    rng.seed = 4701
    var first := Planner.plan(1, false, RunConfig.formal())
    test.equal(first.enemy_counts.get(&"zombie", 0), 10, "room one teaches zombies")
    var boss := Planner.plan(7, false, RunConfig.formal())
    test.check(boss.boss and boss.enemy_counts.is_empty(), "room seven is boss only")
    var doors := Planner.door_choices(3, rng)
    test.equal(doors.size(), 2, "two doors")
    test.check(doors[0].type != doors[1].type, "distinct rewards")
    test.finish(self)
```

- [ ] **Step 2: Run and verify failure**

- [ ] **Step 3: Implement formal and demo plans**

Formal base counts:

| Room | Zombie | Archer | Bat | Knight |
|---:|---:|---:|---:|---:|
| 1 | 10 | 0 | 0 | 0 |
| 2 | 12 | 3 | 0 | 0 |
| 3 | 12 | 4 | 5 | 0 |
| 4 | 14 | 5 | 6 | 1 |
| 5 | 16 | 6 | 8 | 1 |
| 6 | 18 | 7 | 10 | 2 |

When cursed, multiply non-knight counts by `1.35`, add one knight, and set reward count to two. Demo mode rounds each count using `max(1, round(base * spawn_scale))`, keeps one knight in rooms four and six, and uses instant next-wave spawning.

Door dictionaries have keys `type`, `label`, `danger`, `cursed`, `upgrade_count`; use types `weapon`, `ability`, `heal`, `curse`. Room six forces one `curse` offer if neither random door is cursed, so every surviving run sees the risk/reward mechanic. Danger is clamped to one through three skulls. A `weapon` reward requests one weapon-only choice, `ability` requests one three-card passive choice, `heal` restores 35 health and adds five maximum health, and `curse` marks the next room cursed and grants two sequential three-card choices after clearing it.

`RoomManager` spawns at safe perimeter points at least 180 pixels from the player, tracks enemies by signal rather than polling, reveals doors only after zero live enemies, and removes enemies/projectiles/effects on `cleanup_room`.

```gdscript
static func plan(index: int, cursed: bool, config: RunConfig) -> RoomPlan:
    if index == 7:
        return RoomPlan.new(index, 1.6, {}, cursed, true)
    var counts: Dictionary = FORMAL_COUNTS[index].duplicate()
    if config.is_demo:
        for kind in counts:
            counts[kind] = maxi(1, roundi(int(counts[kind]) * config.spawn_scale))
    if cursed:
        for kind in counts:
            if kind != &"knight":
                counts[kind] = ceili(int(counts[kind]) * 1.35)
        counts[&"knight"] = int(counts.get(&"knight", 0)) + 1
    return RoomPlan.new(index, 1.0 + index * 0.1, counts, cursed, false)

static func door_choices(index: int, rng: RandomNumberGenerator) -> Array[Dictionary]:
    var types: Array[StringName] = [&"weapon", &"ability", &"heal", &"curse"]
    var first := types.pop_at(rng.randi_range(0, types.size() - 1))
    var second := types.pop_at(rng.randi_range(0, types.size() - 1))
    if index == 6 and first != &"curse" and second != &"curse":
        second = &"curse"
    return [_door(first, index), _door(second, index)]
```

- [ ] **Step 4: Run planner and room-manager tests**

The integration test starts room one, verifies the expected live count, kills all spawned enemies through `take_damage(9999)`, and asserts `room_cleared` fires once. Expected: exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/rooms scenes/main.tscn tests/unit/test_room_planner.gd tests/integration/test_room_manager.gd
git commit -m "feat: add deterministic rooms and reward doors"
```

---

### Task 8: Game Controller, HUD, Upgrade UI, and Results

**Files:**
- Create: `src/core/copy_zh_tw.gd`
- Create: `src/core/game_controller.gd`
- Create: `src/ui/hud.gd`
- Create: `src/ui/title_screen.gd`
- Create: `src/ui/upgrade_panel.gd`
- Create: `src/ui/results_screen.gd`
- Create: `scenes/ui/hud.tscn`
- Create: `scenes/ui/title_screen.tscn`
- Create: `scenes/ui/upgrade_panel.tscn`
- Create: `scenes/ui/results_screen.tscn`
- Create: `tests/integration/test_game_flow.gd`
- Modify: `scenes/main.tscn`

**Interfaces:**
- Consumes: all prior gameplay signals and domain helpers.
- Produces: `start_run(config)`, `request_upgrade(count, resume_phase)`, `select_door(reward)`, `finish_run(outcome)`, `restart_to_title()`; stable orchestration signals `player_health_changed`, `player_died`, `enemy_died`, `room_cleared`, `door_selected`, `upgrade_requested`, `upgrade_selected`, `boss_defeated`, and `run_finished`.
- Summary dictionary keys: `outcome`, `elapsed_sec`, `kills`, `rooms_cleared`, `weapons`, `stats`, `demo`.

- [ ] **Step 1: Write failing single-finish and flow tests**

```gdscript
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Controller = preload("res://src/core/game_controller.gd")
const RunConfig = preload("res://src/core/run_config.gd")
const GamePhase = preload("res://src/core/game_phase.gd")
var test := TestCase.new()

func _initialize() -> void:
    var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
    root.add_child(main)
    var controller := main.get_node("GameController") as Controller
    var finished_count := [0]
    controller.run_finished.connect(func(_summary): finished_count[0] += 1)
    controller.start_run(RunConfig.demo())
    test.equal(controller.current_room, 1, "run starts in first room")
    controller.finish_run(&"death")
    controller.finish_run(&"timeout")
    test.equal(finished_count[0], 1, "finish is idempotent")
    test.equal(controller.phase, GamePhase.Phase.RESULTS, "results phase")
    main.free()
    test.finish(self)
```

- [ ] **Step 2: Run and verify failure**

- [ ] **Step 3: Implement the composition and player-visible copy**

`GameController` owns `phase`, `config`, `rng`, `remaining_sec`, `current_room`, `kills`, `finished`, player stats, and weapon levels. It starts with soul bolt level one. Combat decrements time; at zero it finishes with `timeout`. Player death finishes with `death`; Boss death finishes with `victory`. It guards every transition through `GamePhase.can_transition`.

```gdscript
signal player_health_changed(current: float, maximum: float)
signal player_died
signal enemy_died(kind: StringName)
signal room_cleared(room_index: int)
signal door_selected(reward: Dictionary)
signal upgrade_requested(choices: Array[StringName])
signal upgrade_selected(id: StringName)
signal boss_defeated
signal run_finished(summary: Dictionary)
```

Connect child signals once in `_ready`: re-emit health and enemy events through these stable names; call `finish_run(&"death")` after `player_died`; call `finish_run(&"victory")` after `boss_defeated`; update HUD only from the stable orchestration signals.

Traditional Chinese copy must include:

- Title: `暮墓餘燼`
- Subtitle: `七分鐘房間式生存 Roguelike`
- Modes: `開始獵殺（7 分鐘）`, `快速展示模式`
- Door labels: `武器祭壇`, `禁忌能力`, `療癒聖泉`, `詛咒寶箱`
- Results: `守墓人已倒下`, `獵魔人殞落`, `時間耗盡`
- Buttons: `再次挑戰`, `返回標題`

Build responsive UI using anchors and theme overrides, not fixed full-screen positions. Upgrades pause only gameplay processing; the UI remains interactive and accepts click or keys one through three. Door selection is physical: `Area2D` exits call `select_door`.

```gdscript
func start_run(next_config: RunConfig) -> void:
    config = next_config
    rng.seed = config.seed_value
    remaining_sec = config.time_limit_sec
    current_room = 1
    kills = 0
    finished = false
    weapon_levels = {&"soul_bolt": 1}
    _transition(GamePhase.Phase.COMBAT)
    room_manager.start_room(RoomPlanner.plan(current_room, false, config))

func finish_run(outcome: StringName) -> void:
    if finished:
        return
    finished = true
    _transition(GamePhase.Phase.RESULTS)
    var summary := {
        "outcome": outcome,
        "elapsed_sec": config.time_limit_sec - remaining_sec,
        "kills": kills,
        "rooms_cleared": current_room - 1,
        "weapons": weapon_levels.duplicate(true),
        "stats": player.get_stats(),
        "demo": config.is_demo,
    }
    run_finished.emit(summary)
```

- [ ] **Step 4: Run integration tests and inspect headless warnings**

Run the flow test, project boot test, and editor import. Expected: exit `0`, no orphan-node errors, and results emitted exactly once for death/timeout/victory.

- [ ] **Step 5: Commit**

```powershell
git add src/core src/ui scenes/ui scenes/main.tscn tests/integration/test_game_flow.gd
git commit -m "feat: connect complete run flow and UI"
```

---

### Task 9: Headless Gravekeeper Boss

**Files:**
- Create: `src/enemies/boss.gd`
- Create: `scenes/enemies/boss.tscn`
- Create: `tests/unit/test_boss.gd`
- Modify: `src/rooms/room_manager.gd`

**Interfaces:**
- Consumes: player target, enemy/projectile scenes, room bounds.
- Produces: signal `died(enemy, &"boss")`, method `configure(difficulty, target)`, method `advance_ai(delta)`, readable `attack_state`, and exactly three attacks `charge`, `tombstones`, `ring`.

- [ ] **Step 1: Write failing deterministic Boss-cycle test**

```gdscript
extends SceneTree

const TestCase = preload("res://tests/support/test_case.gd")
const Boss = preload("res://src/enemies/boss.gd")
var test := TestCase.new()

func _initialize() -> void:
    var boss := Boss.new()
    var observed: Array[StringName] = []
    for index in 3:
        observed.append(boss.choose_next_attack())
    test.equal(observed, [&"charge", &"tombstones", &"ring"], "readable fixed rotation")
    boss.current_health = boss.max_health * 0.49
    test.check(boss.attack_interval() < boss.base_attack_interval, "phase two accelerates")
    boss.free()
    test.finish(self)
```

- [ ] **Step 2: Run and verify failure**

- [ ] **Step 3: Implement telegraphed attacks and phase two**

Boss stats: 1200 HP, speed 52, contact damage 20, base interval 3.2 seconds. Charge displays a 0.7-second red line, then moves at 520 pixels/second for at most 0.7 seconds. Tombstones display three red 36-pixel circles for 0.8 seconds, then create blockers for six seconds; each spawns one zombie after one second. Ring emits 18 projectiles at 150 pixels/second and leaves two adjacent angular gaps. Below 50% HP, use 2.35-second interval; do not overlap attacks or add a fourth attack.

On death, clear Boss projectiles/tombstones, emit once, and leave control to `GameController` for results.

```gdscript
const ATTACK_ORDER: Array[StringName] = [&"charge", &"tombstones", &"ring"]
var next_attack_index := 0

func choose_next_attack() -> StringName:
    var result := ATTACK_ORDER[next_attack_index]
    next_attack_index = (next_attack_index + 1) % ATTACK_ORDER.size()
    return result

func attack_interval() -> float:
    return 2.35 if current_health < max_health * 0.5 else base_attack_interval

func advance_ai(delta: float) -> void:
    attack_cooldown -= delta
    if attack_state == &"idle" and attack_cooldown <= 0.0:
        _begin_attack(choose_next_attack())
```

- [ ] **Step 4: Run Boss test and room-seven integration**

Extend the room integration test: room seven spawns one Boss, zero regular enemies initially, and Boss death clears the room once. Expected: all tests exit `0`.

- [ ] **Step 5: Commit**

```powershell
git add src/enemies/boss.gd scenes/enemies/boss.tscn src/rooms/room_manager.gd tests/unit/test_boss.gd tests/integration/test_room_manager.gd
git commit -m "feat: add telegraphed gravekeeper boss"
```

---

### Task 10: Presentation Assets, Audio Safety, and Recording Mode Polish

**Files:**
- Create: `assets/generated/graveyard_background.png`
- Create: `assets/generated/title_art.png`
- Create: `assets/audio/hit.wav`
- Create: `assets/audio/hurt.wav`
- Create: `assets/audio/upgrade.wav`
- Create: `assets/audio/door.wav`
- Create: `assets/audio/boss_warning.wav`
- Create: `assets/audio/ambience.wav`
- Create: `src/presentation/audio_bus.gd`
- Create: `tests/integration/test_optional_assets.gd`
- Modify: `src/presentation/graveyard_backdrop.gd`
- Modify: `src/core/game_controller.gd`
- Modify: `scenes/ui/title_screen.tscn`

**Interfaces:**
- Consumes: optional asset paths and gameplay events.
- Produces: `AudioBus.play_sfx(id: StringName) -> bool`, `AudioBus.play_path(path: String) -> bool`; presentation that falls back without a crash; deterministic demo sequence using seed 4701.

- [ ] **Step 1: Write the failing optional-asset safety test**

```gdscript
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
```

- [ ] **Step 2: Run and verify failure**

- [ ] **Step 3: Generate and integrate visual/audio assets**

Use the image-generation skill with this exact direction for the background: “Top-down 2D dark-fantasy graveyard floor, charcoal stone, cold desaturated blue moonlight, subtle purple fog, sparse cracked tombstones around the outer edges, empty readable combat area in the center, no characters, no text, seamless game background, 16:9.” Generate title art with: “Transparent-background dark-fantasy title crest, weathered silver frame around an empty central nameplate, dim violet soul flame, compact horizontal composition, no letters, no words, no mockup.” Render the Traditional Chinese title with Godot UI text above the crest so every glyph remains correct.

Downscale with nearest-neighbor treatment and keep gameplay contrast below the code-drawn silhouettes. Create five short mono WAV effects with distinct envelopes plus an original 45–60 second low-volume ambient loop in `ambience.wav`; do not include copyrighted music. `AudioBus.play_path` first checks `ResourceLoader.exists`, returns `false` when absent, and never blocks game flow. Loop ambience through an `AudioStreamPlayer`; expose a title-screen master-volume slider whose minimum is silent and whose default is `-10 dB`.

```gdscript
const SFX_PATHS := {
    &"hit": "res://assets/audio/hit.wav",
    &"hurt": "res://assets/audio/hurt.wav",
    &"upgrade": "res://assets/audio/upgrade.wav",
    &"door": "res://assets/audio/door.wav",
    &"boss_warning": "res://assets/audio/boss_warning.wav",
}

func play_sfx(id: StringName) -> bool:
    return false if id not in SFX_PATHS else play_path(SFX_PATHS[id])

func play_path(path: String) -> bool:
    if not ResourceLoader.exists(path):
        return false
    var player := AudioStreamPlayer.new()
    add_child(player)
    player.stream = load(path)
    player.finished.connect(player.queue_free)
    player.play()
    return true
```

- [ ] **Step 4: Verify demo-mode content and fallback**

Run once with assets present, then temporarily rename one optional art file outside the import step and run the headless asset test/main scene. Expected: present assets load, missing assets fall back to code drawing, demo uses fixed door/upgrade order, and all commands exit `0`. Restore the file before committing.

- [ ] **Step 5: Commit**

```powershell
git add assets src/presentation src/core/game_controller.gd scenes/ui/title_screen.tscn tests/integration/test_optional_assets.gd
git commit -m "feat: polish presentation and recording mode"
```

---

### Task 11: Documentation, Test Runner, and Acceptance Verification

**Files:**
- Create: `README.md`
- Create: `docs/game-report.md`
- Create: `docs/recording-guide.md`
- Create: `tests/run_all.ps1`
- Create: `.gitignore`

**Interfaces:**
- Consumes: all implemented paths, controls, copy, and commands.
- Produces: one-command verification and all written course deliverables except MP4.

- [ ] **Step 1: Create the all-tests runner before final verification**

```powershell
# tests/run_all.ps1
$ErrorActionPreference = 'Stop'
$godotExe = 'C:\Users\user\Desktop\Godot_v4.7.1.exe'
$tests = @(
  'res://tests/integration/test_project_boot.gd',
  'res://tests/unit/test_run_domain.gd',
  'res://tests/unit/test_upgrade_catalog.gd',
  'res://tests/unit/test_player.gd',
  'res://tests/unit/test_enemy_and_projectile.gd',
  'res://tests/unit/test_weapon_controller.gd',
  'res://tests/unit/test_room_planner.gd',
  'res://tests/integration/test_room_manager.gd',
  'res://tests/integration/test_game_flow.gd',
  'res://tests/unit/test_boss.gd',
  'res://tests/integration/test_optional_assets.gd'
)
foreach ($test in $tests) {
  & $godotExe --headless --path . --script $test
  if ($LASTEXITCODE -ne 0) { throw "Godot test failed: $test" }
}
& $godotExe --headless --path . --editor --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import/parser check failed' }
```

- [ ] **Step 2: Run all tests before writing success claims**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1
```

Expected: every listed script exits `0`; final import/parser check exits `0`.

- [ ] **Step 3: Write exact user and course documentation**

`README.md` must include the Godot executable path, editor/open commands, controls, formal/demo modes, folder map, Windows export steps, and troubleshooting for missing optional audio/art.

`docs/game-report.md` must contain:

1. 遊戲介紹與七分鐘核心循環。
2. 市場需求：低門檻、短局、隨機構築、熟悉玩法加房間決策。
3. 開發工具：Godot 4.7.1、GDScript、AI 圖像協作、Git、Codex。
4. 開發過程：前期規劃、原型、TDD、內容製作、平衡、驗證。
5. AI 使用揭露：規格整理、程式協作、背景／標題圖；碰撞與遊戲邏輯由 Godot 資料與測試控制。

`docs/recording-guide.md` must include the approved 0–60 second shot timing, exact Traditional Chinese subtitle lines, 1920×1080 capture settings, and the instruction to record demo mode while retaining a short formal-mode title shot.

- [ ] **Step 4: Perform manual acceptance at two window sizes**

Run formal mode at 1280×720 and 1920×1080. Verify movement, all three weapons, all four ordinary enemies, each door type, curse reward, upgrade keyboard/mouse selection, pause, death, timeout test via debug time override, Boss victory, restart, and no UI overlap. Run demo mode and confirm it supplies every storyboard shot in no more than 75 seconds.

Record findings in a dated “驗收結果” section in `docs/game-report.md`; include only observed results.

- [ ] **Step 5: Inspect repository state and commit**

Run:

```powershell
git status --short
git diff --check
```

Expected: only intended project files are uncommitted; `git diff --check` reports no whitespace errors.

Commit:

```powershell
git add .gitignore README.md docs/game-report.md docs/recording-guide.md tests/run_all.ps1
git commit -m "docs: add delivery report and recording guide"
```

- [ ] **Step 6: Final clean verification**

Run:

```powershell
powershell -ExecutionPolicy Bypass -File .\tests\run_all.ps1
git status --short
```

Expected: all tests exit `0`; repository status is clean. Do not claim completion if either condition is false.
