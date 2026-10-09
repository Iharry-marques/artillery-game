class_name MapDefinition
extends RefCounted
## A generated battlefield: hills/valleys (features), small ripples, floating
## islands and flat spawn pads for each side. Built by BattleMapBuilder.

var id: StringName
var display_name: String
var ground_level_y: float = 12.0
## (centre x, half width, height in u); positive raises the ground.
var features: Array[Vector3] = []
## (amplitude u, frequency rad/u, phase).
var ripples: Array[Vector3] = []
## Floating islands: position = centre, size = radii (u).
var islands: Array[Rect2] = []
## Flat spawn x positions for the left (team 0) and right (team 1) sides.
var left_pads: PackedFloat64Array = PackedFloat64Array()
var right_pads: PackedFloat64Array = PackedFloat64Array()


func all_pads() -> PackedFloat64Array:
	var pads := PackedFloat64Array(left_pads)
	pads.append_array(right_pads)
	return pads
