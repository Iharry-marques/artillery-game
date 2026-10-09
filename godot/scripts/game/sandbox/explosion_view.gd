class_name ExplosionView
extends Node2D
## Short procedural impact feedback: a fading crater/damage circle and floating
## damage numbers. Purely presentational.

const DURATION: float = 0.9
const BLAST_COLOR: Color = Color(1.0, 0.65, 0.25)
const RING_COLOR: Color = Color(1.0, 0.85, 0.4)
const NUMBER_COLOR: Color = Color(1.0, 0.45, 0.4)
const NUMBER_RISE_UNITS: float = 0.6

var rules: CombatRules
var _report: CombatMatch.ImpactReport
var _heads: PackedVector2Array = PackedVector2Array()
var _age: float = DURATION


func show_impact(report: CombatMatch.ImpactReport, combatants: Array[CombatantState]) -> void:
	_report = report
	_heads.clear()
	for c in combatants:
		_heads.append(Vector2(c.head_center_x(), c.head_center_y(rules) - rules.head_radius))
	_age = 0.0


func _process(delta: float) -> void:
	_age += delta
	queue_redraw()


func _draw() -> void:
	if _report == null or _age >= DURATION:
		return
	var t: float = _age / DURATION
	var fade: float = 1.0 - t
	var center: Vector2 = WorldCanvas.to_canvas(_report.x, _report.y)
	var ppu: float = WorldCanvas.PIXELS_PER_UNIT
	if _report.crater:
		draw_circle(center, rules.crater_radius * ppu * (0.6 + 0.4 * t), BLAST_COLOR * Color(1, 1, 1, 0.55 * fade))
		draw_arc(center, rules.damage_radius * ppu, 0.0, TAU, 48, RING_COLOR * Color(1, 1, 1, 0.6 * fade), 2.0 / WorldCanvas.screen_scale(self))
	for i in _report.damages.size():
		if _report.damages[i] > 0:
			var at: Vector2 = WorldCanvas.units_to_canvas(_heads[i]) - Vector2(0.0, NUMBER_RISE_UNITS * ppu * t)
			WorldCanvas.draw_text(self, at, "-%d" % _report.damages[i], NUMBER_COLOR * Color(1, 1, 1, fade))
