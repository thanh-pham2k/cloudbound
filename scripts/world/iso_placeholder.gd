class_name IsoPlaceholder
extends Node2D
## Renders extracted 2.5D isometric RGBA sprites with soft contact shadows and bottom-center Y-sort anchors.

const L := preload("res://scripts/world/hoa_qua_son_layout.gd")
const P := L.PALETTE

const SPRITE_MAP := {
	"hero": {"path": "res://assets/sprites/characters/player_hero.png", "height": 64.0, "center": false, "shadow": Vector2(18.0, 9.0)},
	"elder_npc": {"path": "res://assets/sprites/characters/npc_elder.png", "height": 62.0, "center": false, "shadow": Vector2(16.0, 8.0)},
	"guide_npc": {"path": "res://assets/sprites/characters/npc_guide.png", "height": 58.0, "center": false, "shadow": Vector2(15.0, 8.0)},
	"boar": {"path": "res://assets/sprites/characters/enemy_boar.png", "height": 48.0, "center": false, "shadow": Vector2(20.0, 10.0)},
	"boss": {"path": "res://assets/sprites/characters/boss_demon_king.png", "height": 126.0, "center": false, "shadow": Vector2(36.0, 17.0)},
	"hut": {"path": "res://assets/sprites/environment/hut_main.png", "height": 132.0, "center": false, "shadow": Vector2(58.0, 28.0)},
	"hut_small": {"path": "res://assets/sprites/environment/hut_small.png", "height": 106.0, "center": false, "shadow": Vector2(46.0, 22.0)},
	"peach_tree": {"path": "res://assets/sprites/environment/tree_peach.png", "height": 134.0, "center": false, "shadow": Vector2(34.0, 16.0)},
	"green_tree": {"path": "res://assets/sprites/environment/tree_green.png", "height": 132.0, "center": false, "shadow": Vector2(34.0, 16.0)},
	"rock": {"path": "res://assets/sprites/environment/rock_cluster.png", "height": 54.0, "center": false, "shadow": Vector2(28.0, 13.0)},
	"torch": {"path": "res://assets/sprites/environment/torch_brazier.png", "height": 68.0, "center": false, "shadow": Vector2(15.0, 8.0)},
	"stairs": {"path": "res://assets/sprites/tiles/stairs_stone.png", "height": 78.0, "center": true, "shadow": Vector2.ZERO},
	"spawn_disc": {"path": "res://assets/sprites/interactables/spawn_disc.png", "height": 64.0, "center": true, "shadow": Vector2.ZERO},
	"peach": {"path": "res://assets/sprites/interactables/peach_pickup.png", "height": 34.0, "center": false, "shadow": Vector2(13.0, 6.0)},
	"chest": {"path": "res://assets/sprites/interactables/chest_closed.png", "alt": "res://assets/sprites/interactables/chest_open.png", "height": 46.0, "center": false, "shadow": Vector2(22.0, 10.0)},
	"exit_arch": {"path": "res://assets/sprites/interactables/gate_locked.png", "alt": "res://assets/sprites/interactables/gate_unlocked.png", "height": 124.0, "center": false, "shadow": Vector2(52.0, 22.0)},
}

@export var kind: String = "rock"
@export var item_scale: float = 1.0
@export var facing_dir: Vector2 = Vector2(1.0, 0.5)
@export var hit_flash: float = 0.0
@export var state_active: bool = false

var _sprite: Sprite2D
var _shadow_size: Vector2 = Vector2.ZERO
var _last_state_active: bool = false


func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_apply_visual()


func _process(_delta: float) -> void:
	if not _sprite:
		return
	if _last_state_active != state_active:
		_last_state_active = state_active
		_apply_visual()
	if hit_flash > 0.0:
		_sprite.modulate = Color(2.2, 2.2, 2.2, 1.0)
	else:
		_sprite.modulate = Color.WHITE
	if kind in ["hero", "boar", "boss"] and absf(facing_dir.x) > 0.05:
		_sprite.flip_h = facing_dir.x < 0.0


func _apply_visual() -> void:
	if not _sprite:
		return
	var cfg: Dictionary = SPRITE_MAP.get(kind, SPRITE_MAP["rock"])
	var tex_path: String = cfg["alt"] if (state_active and cfg.has("alt")) else cfg["path"]
	var tex := load(tex_path) as Texture2D
	if tex == null:
		return
	_sprite.texture = tex
	var tex_h := maxf(1.0, float(tex.get_height()))
	var s: float = (float(cfg["height"]) * item_scale) / tex_h
	_sprite.scale = Vector2(s, s)
	_sprite.centered = true
	if cfg["center"]:
		_sprite.offset = Vector2.ZERO
	else:
		_sprite.offset = Vector2(0.0, -tex_h * 0.48)
	_shadow_size = cfg["shadow"] * item_scale
	queue_redraw()


func _draw() -> void:
	if _shadow_size.x <= 0.0:
		return
	var pts := PackedVector2Array()
	for i in 20:
		var a := (float(i) / 20.0) * TAU
		pts.append(Vector2(cos(a) * _shadow_size.x, sin(a) * _shadow_size.y))
	draw_colored_polygon(pts, P["shadow"])
