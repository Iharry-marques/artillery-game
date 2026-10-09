extends ShellScreen
## Game Hall: the simulated room list (create, join, refresh, quick join).

var _list: VBoxContainer
var _name_edit: LineEdit
var _mode: int = 0
var _map_index: int = 0
var _mode_button: Button
var _map_button: Button


func screen_title() -> String:
	return "Game Hall"


func build() -> void:
	if game.rooms.is_empty():
		game.refresh_rooms()
	var row: HBoxContainer = UiKit.hbox(20)
	content_root.add_child(row)
	var left: PanelContainer = UiKit.panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var column: VBoxContainer = UiKit.vbox(10)
	left.add_child(column)
	var header: HBoxContainer = UiKit.hbox(10)
	column.add_child(header)
	header.add_child(UiKit.label("Rooms", 30, UiKit.GOLD, true))
	header.add_child(UiKit.spacer())
	header.add_child(UiKit.button("Quick join", _quick_join, "green", Vector2(170, 48)))
	header.add_child(UiKit.button("Refresh", func() -> void:
		game.refresh_rooms()
		_fill(), "blue", Vector2(150, 48)))
	var titles: HBoxContainer = UiKit.hbox(10)
	column.add_child(titles)
	for entry: Array in [["No.", 70], ["Room", 290], ["Mode", 130], ["Map", 160], ["Players", 110], ["State", 110]]:
		var caption: String = entry[0]
		var title: Label = UiKit.label(caption, 17, UiKit.TEXT_DIM, true)
		var width: int = entry[1]
		title.custom_minimum_size = Vector2(width, 0)
		titles.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_list = UiKit.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	var right: PanelContainer = UiKit.panel()
	right.custom_minimum_size = Vector2(400, 0)
	row.add_child(right)
	var create: VBoxContainer = UiKit.vbox(14)
	right.add_child(create)
	create.add_child(UiKit.label("Create room", 30, UiKit.GOLD, true))
	create.add_child(UiKit.label("Room name", 18, UiKit.TEXT_DIM))
	_name_edit = LineEdit.new()
	_name_edit.text = "%s's room" % game.profile.nickname
	_name_edit.custom_minimum_size = Vector2(360, 50)
	_name_edit.add_theme_font_size_override("font_size", 20)
	create.add_child(_name_edit)
	_mode_button = UiKit.button("", func() -> void:
		_mode = 1 - _mode
		_update_create(), "blue", Vector2(360, 50))
	create.add_child(_mode_button)
	_map_button = UiKit.button("", func() -> void:
		_map_index = (_map_index + 1) % game.content.pvp_maps.size()
		_update_create(), "blue", Vector2(360, 50))
	create.add_child(_map_button)
	create.add_child(UiKit.button("CREATE", _create, "primary", Vector2(360, 64)))
	var note: Label = UiKit.label("Offline build: rooms and players are simulated locally; opponents are AI.", 15, UiKit.TEXT_DIM)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.custom_minimum_size = Vector2(360, 0)
	create.add_child(note)
	_update_create()
	_fill()


func _update_create() -> void:
	_mode_button.text = "Mode: %s" % RoomState.mode_name(_mode)
	var map_id: StringName = game.content.pvp_maps[_map_index]
	_map_button.text = "Map: %s" % game.content.map(map_id).display_name


func _fill() -> void:
	for child in _list.get_children():
		child.queue_free()
	for room in game.rooms:
		var panel: PanelContainer = UiKit.inner_panel()
		_list.add_child(panel)
		var line: HBoxContainer = UiKit.hbox(10)
		panel.add_child(line)
		var cells: Array[Array] = [
			[str(room.id), 70], [("🔒 " if room.locked else "") + room.room_name, 290], [RoomState.mode_name(room.mode), 130],
			[game.content.map(room.map_id).display_name, 160], ["%d / %d" % [room.members.size(), room.capacity()], 110],
			["Playing" if room.state == RoomState.State.PLAYING else "Waiting", 110],
		]
		for cell in cells:
			var text: String = cell[0]
			var width: int = cell[1]
			var label: Label = UiKit.label(text, 18)
			label.custom_minimum_size = Vector2(width, 0)
			line.add_child(label)
		var join: Button = UiKit.button("Join", func() -> void: _join(room), "green", Vector2(110, 44))
		join.disabled = room.state != RoomState.State.WAITING or room.is_full() or room.locked
		line.add_child(join)


func _join(room: RoomState) -> void:
	var error: String = game.join_room(room)
	if error != "":
		toast(error, false)
		return
	ScreenRouter.go(self, &"battle_room")


func _quick_join() -> void:
	for room in game.rooms:
		if room.state == RoomState.State.WAITING and not room.is_full() and not room.locked:
			_join(room)
			return
	toast("No open room. Create one!", false)


func _create() -> void:
	game.create_room(_name_edit.text, _mode, game.content.pvp_maps[_map_index])
	ScreenRouter.go(self, &"battle_room")
