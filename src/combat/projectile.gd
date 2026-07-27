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
	if faction == &"player":
		draw_circle(Vector2.ZERO, 4.0, Color(0.3, 0.8, 1.0, 0.9)) # Soul bolt blue
	else:
		draw_circle(Vector2.ZERO, 3.5, Color(1.0, 0.2, 0.2, 0.9)) # Enemy arrow red
