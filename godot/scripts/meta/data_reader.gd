class_name DataReader
extends RefCounted
## Typed reads from JSON dictionaries (JSON numbers are floats; strict typing
## rejects int()/String() on Variants, assignment to typed locals converts).


static func get_int(data: Dictionary, key: String, default: int = 0) -> int:
	var value: int = data.get(key, default)
	return value


static func get_float(data: Dictionary, key: String, default: float = 0.0) -> float:
	var value: float = data.get(key, default)
	return value


static func get_bool(data: Dictionary, key: String, default: bool = false) -> bool:
	var value: bool = data.get(key, default)
	return value


static func get_string(data: Dictionary, key: String, default: String = "") -> String:
	var value: String = data.get(key, default)
	return value


static func get_string_name(data: Dictionary, key: String) -> StringName:
	return StringName(get_string(data, key))


static func get_dict(data: Dictionary, key: String) -> Dictionary:
	var value: Dictionary = data.get(key, {})
	return value


static func get_array(data: Dictionary, key: String) -> Array:
	var value: Array = data.get(key, [])
	return value
