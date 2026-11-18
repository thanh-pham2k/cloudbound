extends Node2D

const GROUND_SHADER := preload("res://scripts/shaders/terrain_repeat_blend.gdshader")
const SIZE := Vector2(1280, 720)
const LANES := [420.0, 640.0, 860.0]
const LANE_HALF_WIDTH := 110.0
const REAR_LINE_Y := 673.0
const PROTECTED := Rect2(306, 0, 668, 720)
const SCROLL_SPEED := 84.0
const PROP_PERIOD := 1140.0
const ART := "res://assets/survivor/"
# Foot anchors and widths keep the entire art envelope outside the corridor.
const PROPS := [
	["peach_tree", 104, 53, 186], ["green_tree", 1162, 124, 204],
	["rock", 213, 239, 106], ["flower_bush", 1083, 273, 96],
	["green_small", 114, 389, 156], ["peach_small", 1177, 452, 145],
	["flowers", 236, 504, 85], ["rock", 1090, 590, 110],
	["peach_small", 102, 674, 174], ["green_tree", 1190, 780, 180],
	["bush", 214, 836, 105], ["flowers", 1064, 918, 100],
	["green_tree", 107, 1023, 188], ["flower_bush", 1190, 1084, 131],
]

var distance := 0.0
var command_x := 640.0
var _ground: Polygon2D
var _decoration: Array[Sprite2D] = []
var _warning := -1
var _warning_time := 0.0
var _warning_art := preload("res://assets/survivor/spawn.png")


func _ready() -> void:
	var art := preload("res://assets/survivor/grass_light.png")
	var image := Image.create(1, 1, false, Image.FORMAT_RGB8)
	image.fill(Color.WHITE)
	var material_fill := ShaderMaterial.new()
	material_fill.shader = GROUND_SHADER
	material_fill.set_shader_parameter("tile_texture", art)
	material_fill.set_shader_parameter("tile_pixels", art.get_size())
	material_fill.set_shader_parameter("tile_scale", 0.90)
	material_fill.set_shader_parameter("tint", Color(1.0, 1.0, 0.94))
	material_fill.set_shader_parameter("terrain_mask", ImageTexture.create_from_image(image))
	_ground = Polygon2D.new()
	_ground.polygon = PackedVector2Array([Vector2(0, -370), Vector2(1280, -370), SIZE, Vector2(0, 720)])
	_ground.material = material_fill
	_ground.z_index = -2
	add_child(_ground)
	for item in PROPS:
		var prop := Sprite2D.new()
		prop.texture = load(ART + item[0] + ".png")
		prop.scale = Vector2.ONE * float(item[3]) / prop.texture.get_width()
		prop.offset.y = -prop.texture.get_height() * 0.5
		prop.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		prop.z_index = 1
		add_child(prop)
		_decoration.append(prop)
	scroll(0.0)


func scroll(delta: float) -> void:
	distance += SCROLL_SPEED * delta
	var period := float(_ground.material.get_shader_parameter("tile_pixels").y) * 0.90
	_ground.position.y = fposmod(distance, period)
	for i in PROPS.size():
		var data: Array = PROPS[i]
		_decoration[i].position = Vector2(data[1], fposmod(distance + float(data[2]), PROP_PERIOD) - 190.0)
	_warning_time = maxf(0.0, _warning_time - delta)
	queue_redraw()


static func in_lane(x: float, lane: int) -> bool:
	var left: float = LANES[lane] - LANE_HALF_WIDTH
	return x >= left and x < left + 2.0 * LANE_HALF_WIDTH


func warn(lane: int) -> void:
	_warning = lane
	_warning_time = 0.52


func _draw() -> void:
	# Transparent parallel grass bands give direction without hard dividers.
	for x: float in LANES:
		draw_rect(Rect2(x - 96.0, 0, 192, 720), Color(0.98, 1.0, 0.76, 0.115))
		draw_rect(Rect2(x - 106.0, 0, 10, 720), Color(0.98, 1.0, 0.76, 0.054))
		draw_rect(Rect2(x + 96.0, 0, 10, 720), Color(0.98, 1.0, 0.76, 0.054))
		# Each lane ends at the rear defense line.
		draw_line(Vector2(x - 99.0, REAR_LINE_Y), Vector2(x + 99.0, REAR_LINE_Y),
			Color(0.30, 0.42, 0.19, 0.46), 2.0, true)
	# Gold bracket follows the command anchor through a lane change.
	draw_line(Vector2(command_x - 85.0, REAR_LINE_Y), Vector2(command_x + 85.0, REAR_LINE_Y),
		Color("#eed083"), 4.0, true)
	# Offset pairs of small grass marks convey motion and preserve clear silhouettes.
	for i in 24:
		var x := 300.0 + float((i * 137) % 681)
		var y := fposmod(distance + float(i * 109), 792.0) - 36.0
		var ink := Color(0.36, 0.60, 0.28, 0.30)
		draw_line(Vector2(x, y), Vector2(x - 4, y - 5), ink, 1.5, true)
		draw_line(Vector2(x, y), Vector2(x + 3, y - 7), ink, 1.5, true)
	if _warning_time > 0.0:
		draw_texture_rect(_warning_art, Rect2(LANES[_warning] - 32.0, 91, 64, 58),
			false, Color(1.0, 1.0, 1.0, minf(_warning_time * 4.0, 0.95)))
