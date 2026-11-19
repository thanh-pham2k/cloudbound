extends RefCounted
## Appearance pools follow the existing spawn archetypes. Combat uses Actor.kind.

const ART := "res://assets/survivor/enemies/"
const LIGHT := [
	"", "forest_goblin", "shadow_wolf", "mushroom_monster", "cave_bat",
	"bamboo_snake", "demon_rabbit", "fire_imp", "mini_slime", "poison_toad",
	"ice_spirit", "ghost_lantern", "goblin_archer", "shaman_goblin",
]
const HEAVY := ["", "stone_golem", "armored_turtle", "stone_beetle", "wooden_treant", "slime_splitter"]
const ELITES := [
	"", "armored_goblin_captain", "giant_slime", "fire_fox_spirit", "iron_beetle", "phantom_wolf",
]
const BOSSES := {
	"ancient_treant": "Ancient Treant",
	"nine_tailed_fox": "Nine-Tailed Fox",
	"bull_demon_king": "Bull Demon King",
	"golden_dragon": "Golden Dragon",
}
const LEFT_FACING := [
	"shadow_wolf", "bamboo_snake", "demon_rabbit", "fire_fox_spirit",
	"iron_beetle", "phantom_wolf", "nine_tailed_fox", "bull_demon_king", "golden_dragon",
]
const FLOATING := ["cave_bat", "ice_spirit", "ghost_lantern"]

static var _clips := {}


static func clips(id: String) -> SpriteFrames:
	if not _clips.has(id):
		_clips[id] = load(ART.path_join(id + ".tres"))
	return _clips[id] as SpriteFrames
