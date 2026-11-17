class_name HoaQuaSonLayout
extends RefCounted
## Pure Semantic Layout data & Minimal Stylized pastel palette for Hoa Qua Son (Phase 2).
## Kept separate from gameplay logic so coordinates, areas, and batches are easy to tune.

const PALETTE := {
	"ink": Color("#1E293B"),
	"grass_light": Color("#9ED48A"),
	"grass_dark": Color("#7BB86E"),
	"path_cream": Color("#EBD8B7"),
	"path_edge": Color("#D2B991"),
	"stone_light": Color("#D8D2CA"),
	"stone_dark": Color("#9CA3AF"),
	"cliff_slate": Color("#7B8499"),
	"wood_light": Color("#D4A373"),
	"wood_dark": Color("#9C6644"),
	"roof_straw": Color("#E9C46A"),
	"peach_pink": Color("#F9A8D4"),
	"peach_deep": Color("#F472B6"),
	"tree_green": Color("#6BBF7A"),
	"gold": Color("#FBBF24"),
	"crimson": Color("#DC2626"),
	"water_blue": Color("#7CC6EE"),
	"shadow": Color(0.118, 0.161, 0.231, 0.24),
}

const SPAWN_POS := Vector2(0.0, 0.0)

const AREAS := [
	{
		"id": "monkey_village",
		"name": "Làng Khỉ",
		"center": Vector2(40.0, -20.0),
		"radius": Vector2(320.0, 190.0),
		"surface": "village",
	},
	{
		"id": "peach_forest",
		"name": "Rừng Đào",
		"center": Vector2(780.0, -390.0),
		"radius": Vector2(460.0, 260.0),
		"surface": "forest",
	},
	{
		"id": "secret_nook",
		"name": "Khu Bí Mật",
		"center": Vector2(1185.0, -285.0),
		"radius": Vector2(135.0, 88.0),
		"surface": "secret",
	},
	{
		"id": "monster_clearing",
		"name": "Bãi Quái",
		"center": Vector2(1465.0, -815.0),
		"radius": Vector2(300.0, 185.0),
		"surface": "clearing",
	},
	{
		"id": "boss_cave",
		"name": "Hang Boss",
		"center": Vector2(2200.0, -1100.0),
		"radius": Vector2(290.0, 175.0),
		"surface": "cave",
	},
]

const MAIN_PATH_POINTS: Array[Vector2] = [
	Vector2(-30.0, 15.0),
	Vector2(110.0, -45.0),
	Vector2(280.0, -125.0),
	Vector2(500.0, -190.0),
	Vector2(675.0, -325.0),
	Vector2(825.0, -425.0),
	Vector2(1065.0, -515.0),
	Vector2(1320.0, -595.0),
	Vector2(1635.0, -695.0),
	Vector2(1835.0, -875.0),
	Vector2(2020.0, -1010.0),
	Vector2(2200.0, -1100.0),
]

const SECRET_BRANCH_POINTS: Array[Vector2] = [
	Vector2(785.0, -395.0),
	Vector2(985.0, -340.0),
	Vector2(1175.0, -285.0),
]

const HUTS := [
	{"pos": Vector2(-165.0, -125.0), "scale": 1.05, "label": "Hut 01"},
	{"pos": Vector2(115.0, -155.0), "scale": 1.0, "label": "Hut 02"},
	{"pos": Vector2(210.0, 45.0), "scale": 0.95, "label": "Hut 03"},
]

const NPCS := [
	{
		"id": "elder_monkey",
		"name": "Khỉ Trưởng Lão",
		"pos": Vector2(-15.0, -85.0),
		"role": "quest_giver",
	},
	{
		"id": "gate_monkey",
		"name": "Khỉ Gác Cổng",
		"pos": Vector2(255.0, -175.0),
		"role": "guide",
	},
]

const PEACH_TREES := [
	Vector2(415.0, -325.0),
	Vector2(545.0, -445.0),
	Vector2(695.0, -545.0),
	Vector2(935.0, -605.0),
	Vector2(620.0, -190.0),
	Vector2(955.0, -210.0),
]

const GREEN_TREES := [
	Vector2(-245.0, -180.0),
	Vector2(120.0, -220.0),
	Vector2(-150.0, 130.0),
	Vector2(335.0, 75.0),
	Vector2(1245.0, -935.0),
	Vector2(1745.0, -625.0),
	Vector2(1805.0, -765.0),
]

const ROCKS := [
	Vector2(-290.0, 55.0),
	Vector2(455.0, -405.0),
	Vector2(745.0, -230.0),
	Vector2(1235.0, -775.0),
	Vector2(1635.0, -935.0),
	Vector2(1385.0, -685.0),
	Vector2(1890.0, -1000.0),
	Vector2(1955.0, -860.0),
	# Boss cave rim rocks
	Vector2(1990.0, -1185.0),
	Vector2(2115.0, -1255.0),
	Vector2(2285.0, -1260.0),
	Vector2(2445.0, -1155.0),
	Vector2(2415.0, -1005.0),
	Vector2(2250.0, -945.0),
	Vector2(2065.0, -955.0),
]

# Each collectible peach sits right beneath/beside a peach tree trunk (matching original concept)
const PEACH_PICKUPS := [
	Vector2(448.0, -305.0),
	Vector2(578.0, -425.0),
	Vector2(728.0, -525.0),
	Vector2(968.0, -585.0),
	Vector2(652.0, -172.0),
]

const SECRET_SPECIAL_TREE := Vector2(1235.0, -320.0)
const SECRET_CHEST_POS := Vector2(1170.0, -280.0)

# Boar monsters positioned in the clearing slightly left of the winding main path
const MONSTERS := [
	{"id": "boar_1", "name": "Lợn Rừng 1", "pos": Vector2(1365.0, -845.0)},
	{"id": "boar_2", "name": "Lợn Rừng 2", "pos": Vector2(1505.0, -865.0)},
	{"id": "boar_3", "name": "Lợn Rừng 3", "pos": Vector2(1435.0, -760.0)},
]

const BOSS := {
	"id": "demon_king",
	"name": "Yêu Vương",
	"pos": Vector2(2235.0, -1120.0),
}

const BOSS_TORCHES := [
	Vector2(2020.0, -1085.0),
	Vector2(2115.0, -975.0),
]

const BOSS_EXIT_POS := Vector2(2415.0, -1205.0)
const BOSS_CHEST_POS := Vector2(2200.0, -1100.0)

## Outer walkable boundary polygon (counter-clockwise) so the player stays
## inside the 4 connected areas + secret branch without getting stuck.
const WALKABLE_BOUNDARY: Array[Vector2] = [
	Vector2(-320.0, 20.0),
	Vector2(-180.0, 170.0),
	Vector2(140.0, 175.0),
	Vector2(400.0, 30.0),
	Vector2(760.0, -190.0),
	Vector2(1080.0, -135.0),
	Vector2(1335.0, -190.0),
	Vector2(1345.0, -345.0),
	Vector2(1070.0, -385.0),
	Vector2(1300.0, -510.0),
	Vector2(1620.0, -565.0),
	Vector2(1870.0, -720.0),
	Vector2(1940.0, -860.0),
	Vector2(2180.0, -915.0),
	Vector2(2490.0, -1030.0),
	Vector2(2525.0, -1210.0),
	Vector2(2320.0, -1310.0),
	Vector2(2030.0, -1260.0),
	Vector2(1840.0, -1070.0),
	Vector2(1690.0, -965.0),
	Vector2(1350.0, -955.0),
	Vector2(1140.0, -760.0),
	Vector2(680.0, -540.0),
	Vector2(220.0, -290.0),
	Vector2(-150.0, -235.0),
	Vector2(-315.0, -110.0),
]
