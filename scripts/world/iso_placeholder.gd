class_name IsoPlaceholder
extends Node2D
## Renders extracted 2.5D isometric RGBA sprites, animations, and soft contact shadows.

const L := preload("res://scripts/world/hoa_qua_son_layout.gd")
const P := L.PALETTE

const SPRITE_MAP := {
	"cave_front_rim": {"path": "res://assets/sprites/concept/cave_front_rim.png", "height": 54.0, "center": true, "shadow": Vector2.ZERO},
	"hero": {"path": "res://assets/sprites/characters/hero_idle_1.png", "height": 64.0, "center": false, "shadow": Vector2(18.0, 9.0)},
	"elder_npc": {"path": "res://assets/sprites/characters/npc_elder.png", "height": 62.0, "center": false, "shadow": Vector2(16.0, 8.0)},
	"guide_npc": {"path": "res://assets/sprites/characters/npc_guide.png", "height": 58.0, "center": false, "shadow": Vector2(15.0, 8.0)},
	"boar": {"path": "res://assets/sprites/characters/enemy_boar.png", "height": 48.0, "center": false, "shadow": Vector2(20.0, 10.0)},
	"imp": {"path": "res://assets/sprites/characters/enemy_imp.png", "height": 56.0, "center": false, "shadow": Vector2(16.0, 8.0)},
	"boss": {"path": "res://assets/sprites/characters/boss_demon_king.png", "height": 128.0, "center": false, "shadow": Vector2(36.0, 17.0)},
	"hut": {"path": "res://assets/sprites/concept/hut_main_concept.png", "height": 132.0, "center": false, "shadow": Vector2(58.0, 28.0)},
	"hut_small": {"path": "res://assets/sprites/concept/hut_small_concept.png", "height": 106.0, "center": false, "shadow": Vector2(46.0, 22.0)},
	"peach_tree": {"path": "res://assets/sprites/environment/tree_peach.png", "height": 134.0, "center": false, "shadow": Vector2(34.0, 16.0)},
	"green_tree": {"path": "res://assets/sprites/environment/tree_green.png", "height": 132.0, "center": false, "shadow": Vector2(34.0, 16.0)},
	"rock": {"path": "res://assets/sprites/environment/rock_cluster.png", "height": 54.0, "center": false, "shadow": Vector2(28.0, 13.0)},
	"torch": {"path": "res://assets/sprites/environment/torch_brazier.png", "height": 68.0, "center": false, "shadow": Vector2(15.0, 8.0)},
	"fence": {"path": "res://assets/sprites/environment/fence_wooden.png", "height": 56.0, "center": false, "shadow": Vector2(24.0, 10.0)},
	"bridge": {"path": "res://assets/sprites/environment/bridge_wooden.png", "height": 74.0, "center": true, "shadow": Vector2.ZERO},
	"bush": {"path": "res://assets/sprites/environment/bush_green.png", "height": 42.0, "center": false, "shadow": Vector2(22.0, 10.0)},
	"grass_tuft": {"path": "res://assets/sprites/environment/grass_tuft.png", "height": 30.0, "center": false, "shadow": Vector2.ZERO},
	"pebble": {"path": "res://assets/sprites/environment/pebble_cluster.png", "height": 26.0, "center": true, "shadow": Vector2.ZERO},
	"lantern": {"path": "res://assets/sprites/environment/lantern_post.png", "height": 76.0, "center": false, "shadow": Vector2(14.0, 7.0)},
	"stream": {"path": "res://assets/sprites/environment/stream_water.png", "height": 110.0, "center": true, "shadow": Vector2.ZERO},
	"waterfall": {"path": "res://assets/sprites/environment/waterfall.png", "height": 115.0, "center": true, "shadow": Vector2.ZERO},
	"cave_wall": {"path": "res://assets/sprites/concept/cave_back_wide.png", "height": 160.0, "center": false, "shadow": Vector2.ZERO},
	"cliff_corner": {"path": "res://assets/sprites/environment/cliff_corner_ledge.png", "height": 95.0, "center": true, "shadow": Vector2.ZERO},
	"stairs": {"path": "res://assets/sprites/concept/cave_stairs_wide.png", "height": 58.0, "center": true, "shadow": Vector2.ZERO},
	"spawn_disc": {"path": "res://assets/sprites/interactables/spawn_disc.png", "height": 64.0, "center": true, "shadow": Vector2.ZERO},
	"peach": {"path": "res://assets/sprites/interactables/peach_pickup.png", "height": 34.0, "center": false, "shadow": Vector2(13.0, 6.0)},
	"chest": {"path": "res://assets/sprites/interactables/chest_closed.png", "alt": "res://assets/sprites/interactables/chest_open.png", "height": 46.0, "center": false, "shadow": Vector2(22.0, 10.0)},
	"exit_arch": {"path": "res://assets/sprites/interactables/gate_locked.png", "alt": "res://assets/sprites/interactables/gate_unlocked.png", "height": 124.0, "center": false, "shadow": Vector2(52.0, 22.0)},
}

const ANIM_FRAMES := {
	"hero": {
		"idle": ["res://assets/sprites/characters/hero_idle_1.png", "res://assets/sprites/characters/hero_idle_2.png"],
		"run": ["res://assets/sprites/characters/hero_run_1.png", "res://assets/sprites/characters/hero_run_2.png"],
		"attack": ["res://assets/sprites/characters/hero_attack_1.png", "res://assets/sprites/characters/hero_attack_2.png"],
		"dash": ["res://assets/sprites/characters/hero_dash_1.png", "res://assets/sprites/characters/hero_dash_2.png"],
	},
	"boar": {
		"idle": ["res://assets/sprites/characters/enemy_boar.png"],
		"attack": ["res://assets/sprites/characters/enemy_boar_attack.png"],
	},
	"boss": {
		"idle": ["res://assets/sprites/characters/boss_demon_king.png"],
		"attack": ["res://assets/sprites/characters/boss_slam.png"],
	},
}

@export var kind: String = "rock"
@export var item_scale: float = 1.0
@export var facing_dir: Vector2 = Vector2(1.0, 0.5)
@export var hit_flash: float = 0.0
@export var state_active: bool = false
@export var anim_state: String = "idle"

var _sprite: Sprite2D
var _shadow_size: Vector2 = Vector2.ZERO
var _last_tex_path: String = ""
var _anim_timer: float = 0.0


func _ready() -> void:
	_sprite = Sprite2D.new()
	add_child(_sprite)
	_apply_visual()


func _process(delta: float) -> void:
	if not _sprite:
		return
	_anim_timer += delta
	_apply_visual()
	if hit_flash > 0.0:
		_sprite.modulate = Color(2.2, 2.2, 2.2, 1.0)
	else:
		_sprite.modulate = Color.WHITE
	if kind in ["hero", "boar", "imp", "boss"] and absf(facing_dir.x) > 0.05:
		_sprite.flip_h = facing_dir.x < 0.0


func _resolve_tex_path(cfg: Dictionary) -> String:
	if ANIM_FRAMES.has(kind):
		var states: Dictionary = ANIM_FRAMES[kind]
		var frames: Array = states.get(anim_state, states.get("idle", []))
		if frames.size() > 0:
			var fps := 8.0 if anim_state in ["run", "attack", "dash"] else 2.5
			var idx := int(_anim_timer * fps) % frames.size()
			return frames[idx]
	if state_active and cfg.has("alt"):
		return cfg["alt"]
	return cfg["path"]


func _apply_visual() -> void:
	if not _sprite:
		return
	var cfg: Dictionary = SPRITE_MAP.get(kind, SPRITE_MAP["rock"])
	var tex_path := _resolve_tex_path(cfg)
	if tex_path == _last_tex_path:
		return
	_last_tex_path = tex_path

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
