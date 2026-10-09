class_name ProceduralTestMap
extends RefCounted
## One deterministic test map for the sandbox (easy to replace later).
## Flat spawn pads, a hill on the far left, a hill between the spawns, a depression
## on the right with a floating ledge above it (overhang test), and gentle bumps.

const SPAWN_FLAT_HALF_WIDTH: float = 1.5
const SPAWN_BLEND_WIDTH: float = 1.5
## (centre x, half width, height in u); positive height raises the ground.
const FEATURES: Array[Vector3] = [
	Vector3(4.5, 3.5, 3.0),
	Vector3(18.0, 3.0, 2.5),
	Vector3(29.5, 2.5, -2.0),
]
const BUMP_AMPLITUDE: float = 0.35
const BUMP_FREQUENCY: float = 0.9
## Floating ledge above the depression: (x, y, width, height) in u.
const LEDGE: Rect2 = Rect2(30.5, 8.6, 2.5, 0.45)


static func build(rules: CombatRules) -> TerrainMask:
	var columns: int = roundi(rules.map_width / rules.terrain_cell_size)
	var rows: int = roundi(rules.map_height / rules.terrain_cell_size)
	var mask := TerrainMask.new(columns, rows, rules.terrain_cell_size)
	mask.fill_below_surface(func(x: float) -> float: return surface_y(rules, x))
	mask.fill_rect(LEDGE)
	return mask


## Original surface height (world y, smaller = higher) at x.
static func surface_y(rules: CombatRules, x: float) -> float:
	var raise: float = 0.0
	for feature in FEATURES:
		raise += feature.z * _bump(x, feature.x, feature.y)
	raise += BUMP_AMPLITUDE * sin(x * BUMP_FREQUENCY)
	return rules.ground_level_y - raise * _spawn_weight(rules, x)


## 0 on the spawn pads (perfectly flat at ground level), 1 away from them.
static func _spawn_weight(rules: CombatRules, x: float) -> float:
	var weight: float = 1.0
	for spawn in rules.spawn_x:
		var d: float = absf(x - spawn)
		weight = minf(weight, smoothstep(SPAWN_FLAT_HALF_WIDTH, SPAWN_FLAT_HALF_WIDTH + SPAWN_BLEND_WIDTH, d))
	return weight


static func _bump(x: float, center: float, half_width: float) -> float:
	var t: float = clampf((x - center) / half_width, -1.0, 1.0)
	return 0.5 * (cos(PI * t) + 1.0)
