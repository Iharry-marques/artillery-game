class_name LabReferenceMarker
extends Node2D
## Procedural marker whose crosshair centre IS the reference point (no hitbox).
## A faint full-height line keeps the reference x readable at the view edges.

enum Kind { SHOOTER, TARGET }

const SHOOTER_COLOR: Color = Color(0.45, 0.95, 0.55)
const TARGET_COLOR: Color = Color(1.0, 0.6, 0.3)
const RADIUS_PX: float = 10.0
const LINE_WIDTH_PX: float = 2.0
const DASH_PX: float = 6.0
## Half-length of the faint reference line, in u.
const REFERENCE_LINE_UNITS: float = 60.0

@export var kind: Kind = Kind.SHOOTER
var facing: int = 1
var caption: String = ""


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var scale: float = LabView.screen_scale(self)
	var color: Color = SHOOTER_COLOR if kind == Kind.SHOOTER else TARGET_COLOR
	var r: float = RADIUS_PX / scale
	var width: float = LINE_WIDTH_PX / scale
	var reach: float = REFERENCE_LINE_UNITS * LabView.PIXELS_PER_UNIT

	draw_dashed_line(Vector2(0.0, -reach), Vector2(0.0, reach), color * Color(1, 1, 1, 0.25), 1.0 / scale, DASH_PX / scale)
	draw_line(Vector2(-2.0 * r, 0.0), Vector2(2.0 * r, 0.0), color, width)
	draw_line(Vector2(0.0, -2.0 * r), Vector2(0.0, 2.0 * r), color, width)
	if kind == Kind.SHOOTER:
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 32, color, width)
		var tip := Vector2(facing * 3.0 * r, -r)
		draw_line(Vector2(facing * r, -r), tip, color, width)
		draw_line(tip, tip + Vector2(-facing * 0.6 * r, -0.4 * r), color, width)
		draw_line(tip, tip + Vector2(-facing * 0.6 * r, 0.4 * r), color, width)
	else:
		draw_polyline(PackedVector2Array([
			Vector2(0.0, -r), Vector2(r, 0.0), Vector2(0.0, r), Vector2(-r, 0.0), Vector2(0.0, -r)
		]), color, width)
	LabView.draw_text(self, Vector2(1.4 * r, 2.4 * r), caption, color)
