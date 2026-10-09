class_name ScreenRouter
extends RefCounted
## Navigation between the product screens (one scene per screen).

const SCREENS: Dictionary = {
	&"boot": "res://scenes/shell/boot.tscn",
	&"character": "res://scenes/shell/character_create.tscn",
	&"city": "res://scenes/shell/city.tscn",
	&"status": "res://scenes/shell/status.tscn",
	&"bag": "res://scenes/shell/bag.tscn",
	&"shop": "res://scenes/shell/shop.tscn",
	&"blacksmith": "res://scenes/shell/blacksmith.tscn",
	&"game_hall": "res://scenes/shell/game_hall.tscn",
	&"battle_room": "res://scenes/shell/battle_room.tscn",
	&"result": "res://scenes/shell/result.tscn",
	&"expedition": "res://scenes/shell/expedition.tscn",
	&"party_room": "res://scenes/shell/party_room.tscn",
	&"battle": "res://scenes/gameplay/combat_sandbox.tscn",
	&"lab": "res://scenes/debug/ballistics_lab.tscn",
}


static func go(from: Node, screen: StringName) -> void:
	var path: String = SCREENS[screen]
	from.get_tree().change_scene_to_file.call_deferred(path)
