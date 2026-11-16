extends Area2D
class_name OrbPickup

enum Kind { HEALTH, LOOT }

var kind: Kind
var amount: int
var frames: SpriteFrames
var _collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	var shape := CircleShape2D.new()
	shape.radius = 22.0
	var hitbox := CollisionShape2D.new()
	hitbox.shape = shape
	add_child(hitbox)

	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = frames
	sprite.position.y = -20.0
	add_child(sprite)
	sprite.play(&"orb_idle")
	body_entered.connect(_on_body_entered)


func _physics_process(_delta: float) -> void:
	if _collected or kind != Kind.HEALTH:
		return
	for body in get_overlapping_bodies():
		_on_body_entered(body)
		if _collected:
			return


func _on_body_entered(body: Node2D) -> void:
	var player := body as PlayerController
	if _collected or player == null or player.current_hp <= 0:
		return
	if kind == Kind.HEALTH and player.current_hp >= player.max_hp:
		return

	_collected = true
	if kind == Kind.HEALTH:
		player.heal(amount)
	else:
		GameData.award_loot(amount)
	queue_free()
