class_name SandboxDebugOverlay
extends Node2D
## Toggleable diagnostics (F3): 1 u grid, head hitboxes, feet anchors, muzzles,
## last trajectory with its collision segments, impact, crater and damage radii,
## the 10 u camera bounds and the horizontal distance between players.

const GRID_COLOR: Color = Color(1.0, 1.0, 1.0, 0.07)
const GRID_MAJOR_COLOR: Color = Color(0.4, 0.7, 1.0, 0.35)
const HITBOX_COLOR: Color = Color(0.3, 1.0, 1.0)
const ANCHOR_COLOR: Color = Color(1.0, 1.0, 0.3)
const PATH_COLOR: Color = Color(0.4, 0.9, 1.0, 0.8)
const IMPACT_COLOR: Color = Color(1.0, 0.35, 0.35)
const CAMERA_COLOR: Color = Color(1.0, 1.0, 1.0, 0.8)
const TEXT_COLOR: Color = Color(0.9, 0.95, 1.0)
const MAJOR_EVERY_UNITS: int = 5
const LINE_PX: float = 1.5

var combat: CombatMatch
var camera: BattleCamera
var _last_flight: BallisticResult


func remember_flight(result: BallisticResult) -> void:
	_last_flight = result


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if combat == null:
		return
	var scale_px: float = WorldCanvas.screen_scale(self)
	var width: float = LINE_PX / scale_px
	_draw_grid(width)
	_draw_combatants(width)
	_draw_last_flight(width)
	_draw_camera_bounds(width)


func _draw_grid(width: float) -> void:
	var view: Rect2 = camera.visible_rect_units()
	for i in range(floori(view.position.x), ceili(view.end.x) + 1):
		var color: Color = GRID_MAJOR_COLOR if i % MAJOR_EVERY_UNITS == 0 else GRID_COLOR
		draw_line(WorldCanvas.to_canvas(i, view.position.y), WorldCanvas.to_canvas(i, view.end.y), color, width)
		if i % MAJOR_EVERY_UNITS == 0:
			WorldCanvas.draw_text(self, WorldCanvas.to_canvas(i, view.position.y) + Vector2(4.0, 40.0) / WorldCanvas.screen_scale(self), "x %d" % i, GRID_MAJOR_COLOR)
	for j in range(floori(view.position.y), ceili(view.end.y) + 1):
		draw_line(WorldCanvas.to_canvas(view.position.x, j), WorldCanvas.to_canvas(view.end.x, j), GRID_COLOR, width)


func _draw_combatants(width: float) -> void:
	var rules: CombatRules = combat.rules
	for c in combat.combatants:
		var head: Vector2 = WorldCanvas.to_canvas(c.head_center_x(), c.head_center_y(rules))
		draw_arc(head, rules.head_radius * WorldCanvas.PIXELS_PER_UNIT, 0.0, TAU, 40, HITBOX_COLOR, width)
		var feet: Vector2 = WorldCanvas.to_canvas(c.feet_x, c.feet_y)
		var s: float = 6.0 / WorldCanvas.screen_scale(self)
		draw_line(feet + Vector2(-s, 0), feet + Vector2(s, 0), ANCHOR_COLOR, width)
		draw_line(feet + Vector2(0, -s), feet + Vector2(0, s), ANCHOR_COLOR, width)
		draw_circle(WorldCanvas.to_canvas(c.muzzle_x(rules), c.muzzle_y(rules)), s * 0.5, ANCHOR_COLOR)
		WorldCanvas.draw_text(self, feet + Vector2(s, 2.5 * s), "feet (%.2f, %.2f)" % [c.feet_x, c.feet_y], ANCHOR_COLOR)
	var a: CombatantState = combat.combatants[0]
	var b: CombatantState = combat.combatants[1]
	var y: float = maxf(a.feet_y, b.feet_y) + 0.4
	draw_line(WorldCanvas.to_canvas(a.feet_x, y), WorldCanvas.to_canvas(b.feet_x, y), ANCHOR_COLOR, width)
	WorldCanvas.draw_text(
		self, WorldCanvas.to_canvas(0.5 * (a.feet_x + b.feet_x), y) + Vector2(0.0, 18.0) / WorldCanvas.screen_scale(self),
		"D = %.2f u (feet to feet)" % combat.horizontal_distance_between_players(), ANCHOR_COLOR
	)


func _draw_last_flight(width: float) -> void:
	if _last_flight == null or _last_flight.samples.size() < 2:
		return
	var points := PackedVector2Array()
	for sample in _last_flight.samples:
		points.append(WorldCanvas.units_to_canvas(sample))
	draw_polyline(points, PATH_COLOR, width)
	var dot: float = 2.0 / WorldCanvas.screen_scale(self)
	for point in points:
		draw_circle(point, dot, PATH_COLOR)
	var report: CombatMatch.ImpactReport = combat.last_impact
	if report != null and combat.phase != CombatMatch.Phase.FLIGHT:
		var center: Vector2 = WorldCanvas.to_canvas(report.x, report.y)
		draw_circle(center, 4.0 / WorldCanvas.screen_scale(self), IMPACT_COLOR)
		draw_arc(center, combat.rules.crater_radius * WorldCanvas.PIXELS_PER_UNIT, 0.0, TAU, 48, IMPACT_COLOR, width)
		draw_arc(center, combat.rules.damage_radius * WorldCanvas.PIXELS_PER_UNIT, 0.0, TAU, 48, IMPACT_COLOR * Color(1, 1, 1, 0.5), width)
		WorldCanvas.draw_text(self, center + Vector2(8.0, -8.0) / WorldCanvas.screen_scale(self), "impact (%.3f, %.3f) %s" % [report.x, report.y, report.tag], IMPACT_COLOR)


func _draw_camera_bounds(width: float) -> void:
	var view: Rect2 = camera.visible_rect_units()
	var inset: float = 3.0 / WorldCanvas.screen_scale(self)
	var rect := Rect2(WorldCanvas.units_to_canvas(view.position), WorldCanvas.units_to_canvas(view.size)).grow(-inset)
	draw_rect(rect, CAMERA_COLOR, false, width)
	WorldCanvas.draw_text(
		self, rect.position + Vector2(8.0, 60.0) / WorldCanvas.screen_scale(self),
		"camera %.2f x %.2f u | active feet (%.2f, %.2f) | wind %+.1f%s" % [
			view.size.x, view.size.y, combat.active().feet_x, combat.active().feet_y, combat.wind,
			" (forced 0)" if combat.force_zero_wind else ""
		], TEXT_COLOR
	)
