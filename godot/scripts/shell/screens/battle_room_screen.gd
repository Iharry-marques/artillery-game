extends ShellScreen
## Pre-match room: Blue and Red teams, slots, host, ready, map, start. Simulated
## locally; the AI host starts once the player is ready.

const HOST_START_DELAY: float = 2.0

var _teams: Array[VBoxContainer] = []
var _header: Label
var _action: Button
var _status: Label
var _host_timer: float = -1.0


func screen_title() -> String:
	return "Battle Room"


func back_label() -> String:
	return "Leave"


func go_back() -> void:
	game.leave_room()
	ScreenRouter.go(self, &"game_hall")


func build() -> void:
	if game.current_room == null:
		ScreenRouter.go(self, &"game_hall")
		return
	var column: VBoxContainer = UiKit.vbox(14)
	content_root.add_child(column)
	var top: PanelContainer = UiKit.panel()
	column.add_child(top)
	var top_row: HBoxContainer = UiKit.hbox(16)
	top.add_child(top_row)
	_header = UiKit.label("", 26, UiKit.GOLD, true)
	top_row.add_child(_header)
	top_row.add_child(UiKit.spacer())
	if _room().player().is_host:
		top_row.add_child(UiKit.button("Change map", _cycle_map, "blue", Vector2(180, 48)))
		top_row.add_child(UiKit.button("Add AI players", func() -> void:
			game.fill_room_with_ai()
			refresh(), "blue", Vector2(200, 48)))
	top_row.add_child(UiKit.button("Switch team", func() -> void:
		_room().switch_team(_room().player())
		refresh(), "dark", Vector2(170, 48)))
	var teams_row: HBoxContainer = UiKit.hbox(24)
	teams_row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(teams_row)
	for team in 2:
		var panel: PanelContainer = UiKit.panel(Color(0.12, 0.2, 0.42) if team == 0 else Color(0.38, 0.13, 0.17), UiKit.SKY if team == 0 else UiKit.RED)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		teams_row.add_child(panel)
		var team_column: VBoxContainer = UiKit.vbox(12)
		panel.add_child(team_column)
		_teams.append(team_column)
	var bottom: HBoxContainer = UiKit.hbox(16)
	column.add_child(bottom)
	_status = UiKit.label("", 20, UiKit.TEXT)
	bottom.add_child(_status)
	bottom.add_child(UiKit.spacer())
	_action = UiKit.button("", _on_action, "primary", Vector2(320, 70))
	bottom.add_child(_action)
	refresh()


func _room() -> RoomState:
	return game.current_room


func refresh() -> void:
	var room: RoomState = _room()
	var map: MapDefinition = game.content.map(room.map_id)
	_header.text = "Room %d  ·  %s  ·  %s  ·  %s" % [room.id, room.room_name, RoomState.mode_name(room.mode), map.display_name]
	for team in 2:
		var column: VBoxContainer = _teams[team]
		for child in column.get_children():
			child.queue_free()
		column.add_child(UiKit.label("BLUE TEAM" if team == 0 else "RED TEAM", 28, UiKit.SKY if team == 0 else UiKit.RED, true))
		var members: int = 0
		for member in room.members:
			if member.team != team:
				continue
			members += 1
			column.add_child(_member_card(member, team))
		for i in room.team_size() - members:
			var empty: PanelContainer = UiKit.inner_panel()
			empty.custom_minimum_size = Vector2(0, 150)
			empty.add_child(UiKit.label("Open slot", 22, UiKit.TEXT_DIM))
			column.add_child(empty)
	var me: RoomState.Member = room.player()
	if me.is_host:
		var blocker: String = room.start_blocker()
		_action.text = "START"
		_action.disabled = blocker != ""
		_status.text = blocker if blocker != "" else "Everyone is ready. Start the battle!"
	else:
		_action.text = "CANCEL READY" if me.ready else "READY"
		_action.disabled = false
		_status.text = "Waiting for the host..." if me.ready else "Press READY when you are set."
	refresh_top_bar()


func _member_card(member: RoomState.Member, team: int) -> Control:
	var card: PanelContainer = UiKit.inner_panel()
	card.custom_minimum_size = Vector2(0, 150)
	var row: HBoxContainer = UiKit.hbox(14)
	card.add_child(row)
	var preview := CharacterPreview.new()
	preview.custom_minimum_size = Vector2(120, 130)
	preview.outfit = team
	preview.weapon_art = game.content.item(member.weapon_id).weapon_art
	row.add_child(preview)
	var info: VBoxContainer = UiKit.vbox(4)
	row.add_child(info)
	info.add_child(UiKit.label("%s%s" % ["♛ " if member.is_host else "", member.display_name], 24, UiKit.GOLD if member.is_player else UiKit.TEXT, true))
	info.add_child(UiKit.label("Level %d   ·   %s" % [member.level, game.content.item(member.weapon_id).display_name], 17, UiKit.TEXT_DIM))
	var state: String = "HOST" if member.is_host else ("READY" if member.ready else "Not ready")
	info.add_child(UiKit.label(state, 20, UiKit.GREEN if member.ready or member.is_host else UiKit.ORANGE, true))
	return card


func _cycle_map() -> void:
	var maps: Array[StringName] = game.content.pvp_maps
	_room().map_id = maps[(maps.find(_room().map_id) + 1) % maps.size()]
	refresh()


func _on_action() -> void:
	var room: RoomState = _room()
	var me: RoomState.Member = room.player()
	if me.is_host:
		_start()
		return
	me.ready = not me.ready
	_host_timer = HOST_START_DELAY if me.ready else -1.0
	refresh()


func _process(delta: float) -> void:
	if _host_timer < 0.0:
		return
	_host_timer -= delta
	_status.text = "Host starts in %d..." % ceili(maxf(_host_timer, 0.0))
	if _host_timer <= 0.0:
		_host_timer = -1.0
		game.fill_room_with_ai()
		_start()


func _start() -> void:
	var room: RoomState = _room()
	if room.start_blocker() != "":
		toast(room.start_blocker(), false)
		return
	room.state = RoomState.State.PLAYING
	game.pending_battle = game.build_pvp_setup(room)
	ScreenRouter.go(self, &"battle")
