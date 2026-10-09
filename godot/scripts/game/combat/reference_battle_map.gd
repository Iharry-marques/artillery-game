class_name ReferenceBattleMap
extends RefCounted
## The single generated battlefield of the reference clone (Milestone 4).
## Original layout in the classic artillery grammar: a tall hill and cliff on each
## edge, flat spawn pads one battle screen (10 u) apart, walkable rolling humps
## between them, a valley on the right and a floating island over the middle.
## Deterministic and easy to replace; the collision mask is the source of truth.

const SPAWN_FLAT_HALF_WIDTH: float = 1.4
const SPAWN_BLEND_WIDTH: float = 1.6
## (centre x, half width, height in u); positive raises the ground, negative digs.
## Slopes between the spawns stay under ~40 degrees so they can be walked.
const FEATURES: Array[Vector3] = [
	Vector3(3.2, 4.2, 4.2),
	Vector3(8.6, 3.0, 1.1),
	Vector3(16.3, 2.6, 1.3),
	Vector3(19.9, 2.0, 0.85),
	Vector3(27.6, 3.4, -2.4),
	Vector3(33.2, 3.4, 3.4),
]
## Small rolling detail: (amplitude u, frequency rad/u, phase).
const RIPPLES: Array[Vector3] = [Vector3(0.22, 0.8, 0.0), Vector3(0.1, 2.1, 1.0)]
## Floating island (centre and radii in u): an overhang and a mid-field obstacle.
const ISLAND_CENTER: Vector2 = Vector2(18.4, 7.5)
const ISLAND_RADII: Vector2 = Vector2(1.7, 0.42)


static func build(rules: CombatRules) -> TerrainMask:
	var columns: int = roundi(rules.map_width / rules.terrain_cell_size)
	var rows: int = roundi(rules.map_height / rules.terrain_cell_size)
	var mask := TerrainMask.new(columns, rows, rules.terrain_cell_size)
	mask.fill_below_surface(func(x: float) -> float: return surface_y(rules, x))
	mask.fill_ellipse(ISLAND_CENTER, ISLAND_RADII)
	return mask


## Original surface (world y, smaller = higher) at x.
static func surface_y(rules: CombatRules, x: float) -> float:
	var raise: float = 0.0
	for feature in FEATURES:
		raise += feature.z * _bump(x, feature.x, feature.y)
	for ripple in RIPPLES:
		raise += ripple.x * sin(x * ripple.y + ripple.z)
	return rules.ground_level_y - raise * _spawn_weight(rules, x)


## 0 on the spawn pads (flat, exactly at ground level), 1 away from them.
static func _spawn_weight(rules: CombatRules, x: float) -> float:
	var weight: float = 1.0
	for spawn in rules.spawn_x:
		weight = minf(weight, smoothstep(SPAWN_FLAT_HALF_WIDTH, SPAWN_FLAT_HALF_WIDTH + SPAWN_BLEND_WIDTH, absf(x - spawn)))
	return weight


static func _bump(x: float, center: float, half_width: float) -> float:
	var t: float = clampf((x - center) / half_width, -1.0, 1.0)
	return 0.5 * (cos(PI * t) + 1.0)
