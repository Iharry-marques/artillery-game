class_name CombatWorldQuery
extends BallisticCollisionQuery
## Sandbox world collision for projectile segments: terrain, living characters'
## head circles and map bounds (left/right edges, death line). The nearest hit along
## the segment wins.

const TAG_TERRAIN: StringName = &"terrain"
const TAG_HEAD: StringName = &"head"
const TAG_BOUNDS: StringName = &"bounds"

var _terrain: TerrainMask
var _rules: CombatRules
var _combatants: Array[CombatantState]


func _init(terrain: TerrainMask, rules: CombatRules, combatants: Array[CombatantState]) -> void:
	_terrain = terrain
	_rules = rules
	_combatants = combatants


func first_hit(x0: float, y0: float, x1: float, y1: float) -> BallisticHit:
	var best_t: float = INF
	var best_tag: StringName = &""
	var best_collider: Object = null

	var terrain_t: float = _terrain.segment_hit(x0, y0, x1, y1)
	if terrain_t >= 0.0:
		best_t = terrain_t
		best_tag = TAG_TERRAIN

	for combatant in _combatants:
		if not combatant.alive:
			continue
		var head_t: float = segment_circle_hit(
			x0, y0, x1, y1, combatant.head_center_x(), combatant.head_center_y(_rules), _rules.head_radius
		)
		if head_t >= 0.0 and head_t < best_t:
			best_t = head_t
			best_tag = TAG_HEAD
			best_collider = combatant

	var bounds_t: float = _bounds_hit(x0, y0, x1, y1)
	if bounds_t >= 0.0 and bounds_t < best_t:
		best_t = bounds_t
		best_tag = TAG_BOUNDS
		best_collider = null

	if best_tag == &"":
		return null
	return BallisticHit.new(best_t, lerpf(x0, x1, best_t), lerpf(y0, y1, best_t), best_tag, best_collider)


## Fraction where the segment first enters the circle, 0 if it starts inside, -1 if never.
static func segment_circle_hit(x0: float, y0: float, x1: float, y1: float, cx: float, cy: float, r: float) -> float:
	var dx: float = x1 - x0
	var dy: float = y1 - y0
	var fx: float = x0 - cx
	var fy: float = y0 - cy
	var c: float = fx * fx + fy * fy - r * r
	if c <= 0.0:
		return 0.0
	var a: float = dx * dx + dy * dy
	if a == 0.0:
		return -1.0
	var b: float = 2.0 * (fx * dx + fy * dy)
	var discriminant: float = b * b - 4.0 * a * c
	if discriminant < 0.0:
		return -1.0
	var t: float = (-b - sqrt(discriminant)) / (2.0 * a)
	return t if t >= 0.0 and t <= 1.0 else -1.0


## Fraction where the segment leaves the playable area (left edge, right edge or
## death line below the map), or -1. Above the map is open sky.
func _bounds_hit(x0: float, y0: float, x1: float, y1: float) -> float:
	var crossings: Array[float] = [
		_exit_fraction(x0, x1, 0.0, -1.0),
		_exit_fraction(x0, x1, _terrain.width_units(), 1.0),
		_exit_fraction(y0, y1, _rules.death_y(), 1.0),
	]
	var best: float = -1.0
	for t in crossings:
		if t >= 0.0 and (best < 0.0 or t < best):
			best = t
	return best


## Fraction where coordinate a -> b crosses `limit` going outward (outward_sign
## +1: towards larger values, -1: towards smaller values), or -1.
static func _exit_fraction(a: float, b: float, limit: float, outward_sign: float) -> float:
	if (a - limit) * outward_sign <= 0.0 and (b - limit) * outward_sign > 0.0:
		return (limit - a) / (b - a)
	return -1.0
