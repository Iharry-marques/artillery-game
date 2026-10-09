class_name ExplosionView
extends Node2D
## Procedural impact feedback (presentation only): a bright flash, a shock ring,
## expanding smoke puffs, terrain debris particles and bouncing damage numbers.

const FLASH_TIME: float = 0.18
const BLAST_TIME: float = 0.9
const POPUP_TIME: float = 1.4
const FLASH_COLOR: Color = Color(1.0, 0.97, 0.75)
const FIRE_COLOR: Color = Color(1.0, 0.6, 0.2)
const SMOKE_COLOR: Color = Color(0.42, 0.38, 0.4)
const DAMAGE_COLOR: Color = Color(1.0, 0.92, 0.3)
const DAMAGE_OUTLINE: Color = Color(0.45, 0.08, 0.05)
const POPUP_RISE_UNITS: float = 0.7
const POPUP_FONT_SIZE: int = 30
const DEBRIS_COLORS: Array[Color] = [Color(0.82, 0.58, 0.35), Color(0.55, 0.36, 0.24), Color(0.45, 0.78, 0.3)]
const SMOKE_PUFFS: int = 7

var rules: CombatRules
var _report: CombatMatch.ImpactReport
var _age: float = BLAST_TIME
var _popups: Array[Dictionary] = []
var _puff_offsets: PackedVector2Array = PackedVector2Array()


func show_impact(report: CombatMatch.ImpactReport, combatants: Array[CombatantState]) -> void:
	_report = report
	_age = 0.0
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(Vector2(report.x, report.y))
	_puff_offsets.clear()
	for i in SMOKE_PUFFS:
		_puff_offsets.append(Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.2, 0.3)))
	for c in combatants:
		var damage: int = report.damages[c.index] if c.index < report.damages.size() else 0
		if damage > 0:
			_popups.append({"x": c.head_center_x(), "y": c.head_center_y(rules) - rules.head_radius - 0.2, "text": "-%d" % damage, "age": 0.0})
	if report.crater:
		_spawn_debris(rng)


func _process(delta: float) -> void:
	_age += delta
	var alive: Array[Dictionary] = []
	for popup in _popups:
		var age: float = popup["age"]
		popup["age"] = age + delta
		if age + delta < POPUP_TIME:
			alive.append(popup)
	_popups = alive
	queue_redraw()


func _draw() -> void:
	var ppu: float = WorldCanvas.PIXELS_PER_UNIT
	var scale_px: float = WorldCanvas.screen_scale(self)
	if _report != null and _report.crater and _age < BLAST_TIME:
		var center: Vector2 = WorldCanvas.to_canvas(_report.x, _report.y)
		var t: float = _age / BLAST_TIME
		var radius: float = rules.crater_radius * ppu
		for i in _puff_offsets.size():
			var offset: Vector2 = _puff_offsets[i] * radius * (0.6 + 0.9 * t)
			draw_circle(center + offset, radius * (0.35 + 0.35 * t), SMOKE_COLOR * Color(1, 1, 1, 0.55 * (1.0 - t)))
		draw_circle(center, radius * (0.5 + 0.6 * t), FIRE_COLOR * Color(1, 1, 1, 0.75 * (1.0 - t)))
		draw_arc(center, rules.damage_radius * ppu * (0.4 + 0.6 * t), 0.0, TAU, 48, FLASH_COLOR * Color(1, 1, 1, 0.8 * (1.0 - t)), 4.0 / scale_px)
		if _age < FLASH_TIME:
			draw_circle(center, radius * 1.1, FLASH_COLOR * Color(1, 1, 1, 1.0 - _age / FLASH_TIME))
	for popup in _popups:
		var age: float = popup["age"]
		var t: float = age / POPUP_TIME
		var bounce: float = 1.0 + 0.6 * maxf(0.0, 1.0 - age / 0.18)
		var x: float = popup["x"]
		var y: float = popup["y"]
		var text: String = popup["text"]
		var at: Vector2 = WorldCanvas.to_canvas(x - 0.2, y - POPUP_RISE_UNITS * t)
		var fade: float = clampf((1.0 - t) * 2.0, 0.0, 1.0)
		WorldCanvas.draw_text(
			self, at, text, DAMAGE_COLOR * Color(1, 1, 1, fade), roundi(POPUP_FONT_SIZE * bounce), DAMAGE_OUTLINE * Color(1, 1, 1, fade)
		)


func _spawn_debris(rng: RandomNumberGenerator) -> void:
	var debris := CPUParticles2D.new()
	debris.position = WorldCanvas.to_canvas(_report.x, _report.y)
	debris.one_shot = true
	debris.explosiveness = 1.0
	debris.amount = 30
	debris.lifetime = 0.9
	debris.direction = Vector2(0.0, -1.0)
	debris.spread = 80.0
	debris.initial_velocity_min = 180.0
	debris.initial_velocity_max = 480.0
	debris.gravity = Vector2(0.0, 1300.0)
	debris.scale_amount_min = 4.0
	debris.scale_amount_max = 9.0
	debris.color = DEBRIS_COLORS[rng.randi_range(0, DEBRIS_COLORS.size() - 1)]
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1, 1, 1, 1))
	ramp.set_color(1, Color(1, 1, 1, 0))
	debris.color_ramp = ramp
	debris.finished.connect(debris.queue_free)
	add_child(debris)
	debris.emitting = true
