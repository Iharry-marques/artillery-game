class_name BattleMapBuilder
extends RefCounted
## Builds a destructible TerrainMask from a MapDefinition: smooth bumps, ripples,
## flat spawn pads (exactly at ground level) and floating islands. Deterministic.

const PAD_FLAT_HALF_WIDTH: float = 1.4
const PAD_BLEND_WIDTH: float = 1.6


static func build(def: MapDefinition, rules: CombatRules) -> TerrainMask:
	var columns: int = roundi(rules.map_width / rules.terrain_cell_size)
	var rows: int = roundi(rules.map_height / rules.terrain_cell_size)
	var mask := TerrainMask.new(columns, rows, rules.terrain_cell_size)
	var pads: PackedFloat64Array = def.all_pads()
	mask.fill_below_surface(func(x: float) -> float: return surface_y(def, pads, x))
	for island in def.islands:
		mask.fill_ellipse(island.position, island.size)
	return mask


## Original surface (world y, smaller = higher) at x.
static func surface_y(def: MapDefinition, pads: PackedFloat64Array, x: float) -> float:
	var raise: float = 0.0
	for feature in def.features:
		raise += feature.z * _bump(x, feature.x, feature.y)
	for ripple in def.ripples:
		raise += ripple.x * sin(x * ripple.y + ripple.z)
	return def.ground_level_y - raise * _pad_weight(pads, x)


## 0 on the spawn pads (flat, at ground level), 1 away from them.
static func _pad_weight(pads: PackedFloat64Array, x: float) -> float:
	var weight: float = 1.0
	for pad in pads:
		weight = minf(weight, smoothstep(PAD_FLAT_HALF_WIDTH, PAD_FLAT_HALF_WIDTH + PAD_BLEND_WIDTH, absf(x - pad)))
	return weight


static func _bump(x: float, center: float, half_width: float) -> float:
	var t: float = clampf((x - center) / half_width, -1.0, 1.0)
	return 0.5 * (cos(PI * t) + 1.0)
