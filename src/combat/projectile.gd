# src/combat/projectile.gd
class_name Projectile
extends Area2D

var velocity := Vector2.ZERO
var damage := 0.0
var faction := &"player"
var lifetime_left := 2.0
var hit_registered := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	z_index = 15

func launch(dir: Vector2, speed: float, dmg: float, owner_faction: StringName, seconds: float) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	faction = owner_faction
	lifetime_left = seconds
	if dir != Vector2.ZERO:
		rotation = dir.angle()
	
	# Set collision layer / mask based on faction
	if faction == &"player":
		collision_layer = 8
		collision_mask = 2 # Enemy layer
	else:
		collision_layer = 16
		collision_mask = 1 # Player layer

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime_left -= delta
	if lifetime_left <= 0.0:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if hit_registered:
		return
	if faction == &"player" and body.is_in_group("enemies") and body.has_method("take_damage"):
		hit_registered = true
		body.take_damage(damage)
		queue_free()
	elif faction == &"enemy" and body.is_in_group("player") and body.has_method("take_damage"):
		hit_registered = true
		body.take_damage(damage)
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if hit_registered:
		return
	var parent := area.get_parent()
	if parent:
		_on_body_entered(parent)

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := "幽魂彈" if faction == &"player" else "箭"
	var text_color := Color(0.2, 0.95, 1.0, 1.0) if faction == &"player" else Color(1.0, 0.25, 0.25, 1.0)
	var font_size := 18
	var ascent := font.get_ascent(font_size)
	var descent := font.get_descent(font_size)
	var string_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var text_pos := Vector2(-string_size.x / 2.0, (ascent - descent) / 2.0)

	var outline_color := Color(0, 0, 0, 0.95)
	var offsets := [Vector2(-1.5, -1.5), Vector2(1.5, -1.5), Vector2(-1.5, 1.5), Vector2(1.5, 1.5), Vector2(0, 2.0)]
	for off in offsets:
		draw_string(font, text_pos + off, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, outline_color)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
