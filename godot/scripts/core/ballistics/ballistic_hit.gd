class_name BallisticHit
extends RefCounted
## A collision reported by a BallisticCollisionQuery for one trajectory segment.

## Position along the queried segment, 0 = start, 1 = end.
var fraction: float
var x: float
var y: float
## Free label chosen by the query implementation (e.g. &"terrain", &"head").
var tag: StringName
## Whatever was hit, defined by the query implementation (may be null).
var collider: Object


func _init(p_fraction: float, p_x: float, p_y: float, p_tag: StringName, p_collider: Object = null) -> void:
	fraction = p_fraction
	x = p_x
	y = p_y
	tag = p_tag
	collider = p_collider
