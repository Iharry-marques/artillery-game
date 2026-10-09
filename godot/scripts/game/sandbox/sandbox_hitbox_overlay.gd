class_name SandboxHitboxOverlay
extends Node2D
## F2 review mode: the gameplay geometry drawn over the art, to judge whether the
## hittable head feels too large or too small. Shows, per character: the visual
## head outline from the proxy art metadata (dashed), the HeadHitbox circle (solid),
## the FeetAnchor, the WeaponPivot, the launch point at the current angle and the
## mathematical aim vector.

const VISUAL_COLOR: Color = Color(1.0, 0.95, 0.4)
const HITBOX_COLOR: Color = Color(0.2, 1.0, 1.0)
const ANCHOR_COLOR: Color = Color(1.0, 0.4, 1.0)
const AIM_COLOR: Color = Color(1.0, 1.0, 1.0)
const AIM_LENGTH_UNITS: float = 1.4
const LINE_PX: float = 2.0
const LABEL_FONT: int = 13

var combat: CombatMatch
var art: CharacterProxyArt


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if combat == null:
		return
	var ppu: float = WorldCanvas.PIXELS_PER_UNIT
	var scale_px: float = WorldCanvas.screen_scale(self)
	var width: float = LINE_PX / scale_px
	var rules: CombatRules = combat.rules
	for c in combat.combatants:
		var visual_center: Vector2 = WorldCanvas.to_canvas(c.feet_x + c.facing * art.head_center_u.x, c.feet_y - art.head_center_u.y)
		_dashed_ellipse(visual_center, art.head_visual_radius_u * ppu, VISUAL_COLOR, width)
		var hit_center: Vector2 = WorldCanvas.to_canvas(c.head_center_x(), c.head_center_y(rules))
		draw_arc(hit_center, rules.head_radius * ppu, 0.0, TAU, 48, HITBOX_COLOR, width)
		draw_circle(hit_center, 3.0 / scale_px, HITBOX_COLOR)

		var feet: Vector2 = WorldCanvas.to_canvas(c.feet_x, c.feet_y)
		var s: float = 7.0 / scale_px
		draw_line(feet + Vector2(-s, 0), feet + Vector2(s, 0), ANCHOR_COLOR, width)
		draw_line(feet + Vector2(0, -s), feet + Vector2(0, s), ANCHOR_COLOR, width)
		draw_circle(WorldCanvas.to_canvas(c.weapon_pivot_x(rules), c.weapon_pivot_y(rules)), 3.5 / scale_px, ANCHOR_COLOR)

		var muzzle: Vector2 = WorldCanvas.to_canvas(c.muzzle_x(rules, c.angle), c.muzzle_y(rules, c.angle))
		var radians: float = deg_to_rad(c.angle)
		var direction := Vector2(c.facing * cos(radians), -sin(radians))
		var tip: Vector2 = muzzle + direction * AIM_LENGTH_UNITS * ppu
		draw_line(muzzle, tip, AIM_COLOR, width)
		draw_line(tip, tip - direction.rotated(0.4) * 10.0 / scale_px, AIM_COLOR, width)
		draw_line(tip, tip - direction.rotated(-0.4) * 10.0 / scale_px, AIM_COLOR, width)
		draw_circle(muzzle, 4.0 / scale_px, AIM_COLOR)

		var label_at: Vector2 = hit_center + Vector2(rules.head_radius * ppu + 10.0 / scale_px, 0.0)
		WorldCanvas.draw_text(self, label_at, "hitbox r %.2f u" % rules.head_radius, HITBOX_COLOR, LABEL_FONT, Color(0, 0, 0, 0.85))
		WorldCanvas.draw_text(
			self, label_at + Vector2(0, 16.0 / scale_px),
			"art head %.2f x %.2f u" % [art.head_visual_radius_u.x, art.head_visual_radius_u.y], VISUAL_COLOR, LABEL_FONT, Color(0, 0, 0, 0.85)
		)
		WorldCanvas.draw_text(self, tip + Vector2(8.0, 4.0) / scale_px, "aim %d° (launch point at barrel tip)" % c.angle, AIM_COLOR, LABEL_FONT, Color(0, 0, 0, 0.85))


func _dashed_ellipse(center: Vector2, radii: Vector2, color: Color, width: float) -> void:
	var segments: int = 48
	for i in segments:
		if i % 2 == 1:
			continue
		var a0: float = TAU * i / segments
		var a1: float = TAU * (i + 1) / segments
		draw_line(center + Vector2(cos(a0), sin(a0)) * radii, center + Vector2(cos(a1), sin(a1)) * radii, color, width)
