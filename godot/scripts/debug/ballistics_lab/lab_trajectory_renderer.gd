class_name LabTrajectoryRenderer
extends Node2D
## Draws a BallisticResult exactly as ProjectileSimulation sampled it: the path,
## launch point, apex, target plane, plane crossing and the horizontal impact error.
## It never evaluates trajectory math of its own.

const PATH_COLOR: Color = Color(0.3, 0.85, 0.95)
const LAUNCH_COLOR: Color = Color(0.95, 0.95, 0.95)
const APEX_COLOR: Color = Color(0.75, 0.6, 1.0)
const PLANE_COLOR: Color = Color(1.0, 0.75, 0.3, 0.7)
const IMPACT_COLOR: Color = Color(1.0, 0.35, 0.35)
const ERROR_COLOR: Color = Color(1.0, 0.85, 0.35)
const PATH_WIDTH_PX: float = 2.5
const MARK_RADIUS_PX: float = 5.0
const DASH_PX: float = 8.0
## Extra plane length drawn beyond shooter/target/impact, in u.
const PLANE_MARGIN_UNITS: float = 3.0
## Vertical gap between the target plane and the error bracket, in screen px.
const ERROR_BRACKET_GAP_PX: float = 22.0

var _setup: LabShotSetup
var _result: BallisticResult


func show_result(setup: LabShotSetup, result: BallisticResult) -> void:
	_setup = setup
	_result = result
	queue_redraw()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if _result == null or _result.samples.is_empty():
		return
	var scale: float = LabView.screen_scale(self)
	var target_x: float = _setup.target_x()
	var target_y: float = _setup.target_y()

	var plane_left: float = minf(minf(0.0, target_x), _result.impact_x) - PLANE_MARGIN_UNITS
	var plane_right: float = maxf(maxf(0.0, target_x), _result.impact_x) + PLANE_MARGIN_UNITS
	draw_dashed_line(
		LabView.to_canvas(plane_left, target_y), LabView.to_canvas(plane_right, target_y),
		PLANE_COLOR, 1.5 / scale, DASH_PX / scale
	)

	var points := PackedVector2Array()
	for sample in _result.samples:
		points.append(LabView.units_to_canvas(sample))
	draw_polyline(points, PATH_COLOR, PATH_WIDTH_PX / scale, true)

	draw_circle(LabView.to_canvas(0.0, 0.0), MARK_RADIUS_PX / scale, LAUNCH_COLOR)
	_draw_apex(scale)
	if _result.hit_plane():
		_draw_impact(scale, target_x, target_y)
	else:
		var last: Vector2 = LabView.units_to_canvas(_result.samples[_result.samples.size() - 1])
		LabView.draw_text(self, last + Vector2(8.0, -8.0) / scale, "NO IMPACT: %s" % _result.termination_name(), IMPACT_COLOR)


func _draw_apex(scale: float) -> void:
	var apex: Vector2 = LabView.to_canvas(_result.apex_x, _result.apex_y)
	draw_dashed_line(apex, LabView.to_canvas(_result.apex_x, 0.0), APEX_COLOR * Color(1, 1, 1, 0.5), 1.0 / scale, DASH_PX / scale)
	draw_circle(apex, MARK_RADIUS_PX / scale, APEX_COLOR)
	LabView.draw_text(
		self, apex + Vector2(8.0, -8.0) / scale,
		"apex x %.3f, y %.3f (%.3f u above launch)" % [_result.apex_x, _result.apex_y, -_result.apex_y], APEX_COLOR
	)


func _draw_impact(scale: float, target_x: float, target_y: float) -> void:
	var impact: Vector2 = LabView.to_canvas(_result.impact_x, _result.impact_y)
	var r: float = (MARK_RADIUS_PX + 2.0) / scale
	draw_line(impact + Vector2(-r, -r), impact + Vector2(r, r), IMPACT_COLOR, 2.0 / scale)
	draw_line(impact + Vector2(-r, r), impact + Vector2(r, -r), IMPACT_COLOR, 2.0 / scale)

	var gap: float = ERROR_BRACKET_GAP_PX / scale
	var from: Vector2 = LabView.to_canvas(target_x, target_y) + Vector2(0.0, gap)
	var to: Vector2 = Vector2(impact.x, from.y)
	var tick: float = 5.0 / scale
	draw_line(from, to, ERROR_COLOR, 2.0 / scale)
	draw_line(from + Vector2(0.0, -tick), from + Vector2(0.0, tick), ERROR_COLOR, 2.0 / scale)
	draw_line(to + Vector2(0.0, -tick), to + Vector2(0.0, tick), ERROR_COLOR, 2.0 / scale)
	var error: float = _setup.impact_error(_result)
	var along: float = _setup.impact_error_along_shot(_result)
	LabView.draw_text(
		self, Vector2(minf(from.x, to.x), from.y + 18.0 / scale),
		"impact x %.4f | error %+.4f u (%s)" % [_result.impact_x, error, "long" if along > 0.0 else "short"],
		ERROR_COLOR
	)
