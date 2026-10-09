class_name CharacterMotor
extends RefCounted
## Deterministic terrain-following movement and support (no rigid bodies, no jump).
##
## Support is probed under the FeetAnchor at three x positions (centre and
## +/- foot_half_width); the highest ground found wins, so a character can stand
## on an edge as long as one probe touches terrain.

## Small tolerance for "already standing on the ground", in u.
const GROUND_EPSILON: float = 0.001


## Top of the support under the feet when scanning down from from_y, or NAN.
static func support_y(terrain: TerrainMask, rules: CombatRules, x: float, from_y: float) -> float:
	var best: float = NAN
	for offset: float in [-rules.foot_half_width, 0.0, rules.foot_half_width]:
		var ground: float = terrain.ground_below(x + offset, from_y)
		if not is_nan(ground) and (is_nan(best) or ground < best):
			best = ground
	return best


static func is_supported(terrain: TerrainMask, rules: CombatRules, state: CombatantState) -> bool:
	var ground: float = support_y(terrain, rules, state.feet_x, state.feet_y - terrain.cell_size)
	return not is_nan(ground) and ground <= state.feet_y + GROUND_EPSILON


## Moves horizontally by up to |distance| (sign = direction), following the
## surface. Climbs slopes up to max_slope_degrees, stops at walls and map edges,
## and walks off ledges (falling is handled by fall()). Returns the distance moved.
static func walk(terrain: TerrainMask, rules: CombatRules, state: CombatantState, distance: float) -> float:
	var direction: float = signf(distance)
	var remaining: float = absf(distance)
	var moved: float = 0.0
	var step: float = terrain.cell_size * 0.5
	var climb_per_step: float = step * tan(deg_to_rad(rules.max_slope_degrees)) + terrain.cell_size
	var min_x: float = rules.foot_half_width
	var max_x: float = terrain.width_units() - rules.foot_half_width
	while remaining > 0.0 and direction != 0.0:
		var dx: float = minf(step, remaining)
		var new_x: float = state.feet_x + direction * dx
		if new_x < min_x or new_x > max_x:
			break
		var scan_from: float = state.feet_y - climb_per_step
		var ground: float = support_y(terrain, rules, new_x, scan_from)
		if not is_nan(ground) and ground <= scan_from + GROUND_EPSILON:
			break
		var new_y: float = state.feet_y
		if not is_nan(ground) and ground <= state.feet_y + climb_per_step:
			new_y = ground
		if terrain.is_solid(new_x, new_y - rules.head_center_height):
			break
		state.feet_x = new_x
		state.feet_y = new_y
		remaining -= dx
		moved += dx
	return moved


## Lets the character fall by up to `distance`, stopping on support. Returns true
## once the character is supported. Characters below rules.death_y() are defeated.
static func fall(terrain: TerrainMask, rules: CombatRules, state: CombatantState, distance: float) -> bool:
	if not state.alive:
		return true
	var ground: float = support_y(terrain, rules, state.feet_x, state.feet_y - terrain.cell_size)
	if not is_nan(ground) and ground <= state.feet_y + GROUND_EPSILON:
		state.feet_y = minf(state.feet_y, ground)
		return true
	var target: float = state.feet_y + distance
	if not is_nan(ground) and ground <= target:
		state.feet_y = ground
		return true
	state.feet_y = target
	if state.feet_y > rules.death_y():
		state.defeat()
		return true
	return false


## Drops the character straight onto its support (used at spawn).
static func place_on_ground(terrain: TerrainMask, rules: CombatRules, state: CombatantState) -> void:
	var ground: float = support_y(terrain, rules, state.feet_x, 0.0)
	if not is_nan(ground):
		state.feet_y = ground
