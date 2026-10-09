extends ShellScreen
## The City hub (classic hub-and-spoke layout): illustrated buildings lead to the
## Game Hall, Expedition, Blacksmith, Shop, Guild, Mail and Hall of Fame; the player
## panel sits top-left, system messages bottom-left, shortcuts bottom-right.

const BUILDINGS: Array[Dictionary] = [
	{"key": "guild", "title": "Guild", "subtitle": "Societies (preview)", "center": Vector2(270, 330), "size": 230.0},
	{"key": "game_hall", "title": "Game Hall", "subtitle": "PvP rooms", "center": Vector2(800, 330), "size": 360.0},
	{"key": "ranking", "title": "Hall of Fame", "subtitle": "Rankings", "center": Vector2(1330, 330), "size": 230.0},
	{"key": "blacksmith", "title": "Blacksmith", "subtitle": "Strengthen, compose, fuse", "center": Vector2(360, 585), "size": 260.0},
	{"key": "shop", "title": "Shop", "subtitle": "Weapons, clothes, materials", "center": Vector2(640, 660), "size": 270.0},
	{"key": "expedition", "title": "Expedition Pier", "subtitle": "PvE dungeons", "center": Vector2(985, 660), "size": 290.0},
	{"key": "mail", "title": "Post Office", "subtitle": "Mail and rewards", "center": Vector2(1320, 640), "size": 230.0},
]
const MOCK_FRIENDS: Array[Array] = [
	["Lumi", 4, true], ["Captain Bolt", 6, true], ["Mochi", 2, false], ["Tansy", 5, false], ["Ziggy", 3, true],
]
const MOCK_RANKING: Array[Array] = [
	["Nova", 12, 4810], ["Rook", 11, 4420], ["Juniper", 10, 3980], ["Pepper", 9, 3610], ["Sora", 8, 3150],
	["Hazel", 7, 2760], ["Kiko", 6, 2420], ["Bramble", 5, 2010], ["Quill", 4, 1700],
]

var _player_panel: VBoxContainer
var _badges: Dictionary = {}


func has_top_bar() -> bool:
	return false


func _style_backdrop(backdrop: ScreenBackdrop) -> void:
	backdrop.top_color = Color(0.38, 0.68, 1.0)
	backdrop.bottom_color = Color(0.98, 0.9, 0.72)
	backdrop.hill_color = Color(0.55, 0.82, 0.5)


func build() -> void:
	var plaza := _Plaza.new()
	plaza.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(plaza)
	var art_root := Control.new()
	art_root.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	art_root.position = Vector2(-800, -450)
	art_root.size = Vector2(1600, 900)
	art_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art_root)
	for spec in BUILDINGS:
		var key: String = spec["key"]
		var center: Vector2 = spec["center"]
		var building_size: float = spec["size"]
		var title: String = spec["title"]
		var subtitle: String = spec["subtitle"]
		var building := CityBuilding.create(load("res://assets/city/%s.png" % key) as Texture2D, title, subtitle, center, building_size)
		building.activated.connect(func() -> void: _open_building(key))
		art_root.add_child(building)
	_build_player_panel()
	_build_system_log()
	_build_shortcuts()
	refresh()


func refresh() -> void:
	for child in _player_panel.get_children():
		child.queue_free()
	var p: PlayerProfile = game.profile
	var stats: CharacterStats = game.stats()
	var header: HBoxContainer = UiKit.hbox(12)
	_player_panel.add_child(header)
	var avatar := CharacterPreview.new()
	avatar.custom_minimum_size = Vector2(96, 110)
	avatar.show_profile(p, game.content)
	header.add_child(avatar)
	var info: VBoxContainer = UiKit.vbox(2)
	header.add_child(info)
	info.add_child(UiKit.label(p.nickname, 26, UiKit.GOLD, true))
	info.add_child(UiKit.label("Level %d     Power %d" % [p.level, stats.combat_power], 18))
	var exp_bar := ProgressBar.new()
	exp_bar.custom_minimum_size = Vector2(230, 16)
	exp_bar.show_percentage = false
	exp_bar.max_value = Progression.exp_to_next(p.level)
	exp_bar.value = p.exp
	exp_bar.add_theme_stylebox_override("fill", UiKit.box(UiKit.SKY, Color(0, 0, 0, 0), 6, 0))
	info.add_child(exp_bar)
	info.add_child(UiKit.label("EXP %d / %d     HP %d" % [p.exp, Progression.exp_to_next(p.level), stats.max_hp], 15, UiKit.TEXT_DIM))
	_player_panel.add_child(UiKit.label("●  %s Gold     ◆  %s Coupons     ✦  %s Vouchers" % [TopBar._format(p.wallet.gold), TopBar._format(p.wallet.coupons), TopBar._format(p.wallet.vouchers)], 16))
	_update_badges()


func _build_player_panel() -> void:
	var panel: PanelContainer = UiKit.panel(Color(0.1, 0.14, 0.28, 0.92))
	panel.position = Vector2(16, 16)
	add_child(panel)
	_player_panel = UiKit.vbox(6)
	panel.add_child(_player_panel)


func _build_system_log() -> void:
	var panel: PanelContainer = UiKit.panel(Color(0.05, 0.07, 0.16, 0.78), Color(1, 1, 1, 0.2), 12)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	panel.position = Vector2(16, -196)
	panel.custom_minimum_size = Vector2(460, 0)
	add_child(panel)
	var column: VBoxContainer = UiKit.vbox(4)
	panel.add_child(column)
	column.add_child(UiKit.label("[World] System", 16, UiKit.GOLD, true))
	var lines: PackedStringArray = [
		"Welcome to the city, %s!" % game.profile.nickname,
		"Tip: strengthen your weapon at the Blacksmith.",
		"Battles: %d   PvP wins: %d   Expeditions cleared: %d" % [game.profile.counter(&"battles"), game.profile.counter(&"pvp_wins"), game.profile.counter(&"pve_clears")],
		"Offline build: rooms, players and rankings are simulated.",
	]
	for line in lines:
		column.add_child(UiKit.label(line, 15, UiKit.TEXT))


func _build_shortcuts() -> void:
	var row: HBoxContainer = UiKit.hbox(10)
	row.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	row.position = Vector2(-940, -92)
	add_child(row)
	var shortcuts: Array[Array] = [
		["Bag", func() -> void: ScreenRouter.go(self, &"bag"), "primary", "bag"],
		["Status", func() -> void: ScreenRouter.go(self, &"status"), "primary", "status"],
		["Quests", _open_quests, "gold", "quests"],
		["Mail", _open_mail, "gold", "mail"],
		["Friends", _open_friends, "blue", "friends"],
		["Ranking", _open_ranking, "blue", "ranking"],
		["Settings", _open_settings, "dark", "settings"],
	]
	for entry in shortcuts:
		var callback: Callable = entry[1]
		var caption: String = entry[0]
		var variant: String = entry[2]
		var button: Button = UiKit.button(caption, callback, variant, Vector2(124, 64))
		row.add_child(button)
		var badge: Label = UiKit.label("", 16, UiKit.TEXT, true)
		badge.add_theme_stylebox_override("normal", UiKit.box(UiKit.RED, Color.WHITE, 10, 2))
		badge.position = Vector2(96, -12)
		badge.visible = false
		button.add_child(badge)
		var key: String = entry[3]
		_badges[key] = badge


func _update_badges() -> void:
	var counts: Dictionary = {"quests": game.claimable_quests(), "mail": game.unread_mails()}
	for key: String in counts:
		var badge: Label = _badges.get(key, null)
		if badge == null:
			continue
		var count: int = counts[key]
		badge.text = " %d " % count
		badge.visible = count > 0


func _open_building(key: String) -> void:
	match key:
		"game_hall":
			ScreenRouter.go(self, &"game_hall")
		"expedition":
			ScreenRouter.go(self, &"expedition")
		"blacksmith":
			ScreenRouter.go(self, &"blacksmith")
		"shop":
			ScreenRouter.go(self, &"shop")
		"mail":
			_open_mail()
		"ranking":
			_open_ranking()
		"guild":
			_open_guild()


# --- Modals -----------------------------------------------------------------------------


func _open_quests() -> void:
	var modal: ModalWindow = ModalWindow.open(self, "Quests")
	_fill_quests(modal)


func _fill_quests(modal: ModalWindow) -> void:
	modal.clear_body()
	for quest in game.content.quests:
		var state: Dictionary = game.quest_state(quest.id)
		var progress: int = state["progress"]
		var claimed: bool = state["claimed"]
		var row: PanelContainer = UiKit.inner_panel()
		modal.body.add_child(row)
		var line: HBoxContainer = UiKit.hbox(14)
		row.add_child(line)
		var text: VBoxContainer = UiKit.vbox(2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		text.add_child(UiKit.label(quest.title, 22, UiKit.GOLD if not claimed else UiKit.TEXT_DIM, true))
		text.add_child(UiKit.label(quest.description, 16, UiKit.TEXT))
		text.add_child(UiKit.label("Reward: %s" % _reward_text(quest.reward), 15, UiKit.TEXT_DIM))
		line.add_child(UiKit.label("%d / %d" % [progress, quest.target], 20))
		if claimed:
			line.add_child(UiKit.label("Claimed ✓", 18, UiKit.GREEN, true))
		else:
			var claim: Button = UiKit.button("Claim", func() -> void:
				var error: String = game.claim_quest(quest.id)
				toast("Reward claimed!" if error == "" else error, error == "")
				_fill_quests(modal)
				refresh(), "green", Vector2(120, 48))
			claim.disabled = progress < quest.target
			line.add_child(claim)
	modal.closed.connect(refresh)


func _open_mail() -> void:
	var modal: ModalWindow = ModalWindow.open(self, "Mailbox")
	_fill_mail(modal)


func _fill_mail(modal: ModalWindow) -> void:
	modal.clear_body()
	if game.profile.mails.is_empty():
		modal.body.add_child(UiKit.label("No mail.", 20, UiKit.TEXT_DIM))
	for i in range(game.profile.mails.size() - 1, -1, -1):
		var mail: MailMessage = game.profile.mails[i]
		var row: PanelContainer = UiKit.inner_panel()
		modal.body.add_child(row)
		var line: HBoxContainer = UiKit.hbox(14)
		row.add_child(line)
		var text: VBoxContainer = UiKit.vbox(2)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		line.add_child(text)
		text.add_child(UiKit.label("%s  —  %s" % [mail.sender, mail.subject], 20, UiKit.GOLD, true))
		var body: Label = UiKit.label(mail.body, 16)
		body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		body.custom_minimum_size = Vector2(560, 0)
		text.add_child(body)
		if not mail.attachment.is_empty():
			text.add_child(UiKit.label("Attachment: %s" % _reward_text(mail.attachment), 15, UiKit.TEXT_DIM))
		if mail.has_unclaimed_attachment():
			line.add_child(UiKit.button("Claim", func() -> void:
				game.claim_mail(mail)
				toast("Attachment claimed!")
				_fill_mail(modal)
				refresh(), "green", Vector2(120, 48)))
		else:
			line.add_child(UiKit.label("✓", 22, UiKit.GREEN, true))
	modal.closed.connect(refresh)


func _open_friends() -> void:
	var modal: ModalWindow = ModalWindow.open(self, "Friends", Vector2(700, 560))
	modal.body.add_child(UiKit.label("Offline build: a sample friend list (no networking yet).", 16, UiKit.TEXT_DIM))
	for entry in MOCK_FRIENDS:
		var row: PanelContainer = UiKit.inner_panel()
		modal.body.add_child(row)
		var line: HBoxContainer = UiKit.hbox(14)
		row.add_child(line)
		var online: bool = entry[2]
		line.add_child(UiKit.label("●", 22, UiKit.GREEN if online else Color(0.5, 0.5, 0.55)))
		line.add_child(UiKit.label("%s   Lv %d" % [entry[0], entry[1]], 20))
		line.add_child(UiKit.spacer())
		line.add_child(UiKit.label("Online" if online else "Offline", 16, UiKit.TEXT_DIM))


func _open_ranking() -> void:
	var modal: ModalWindow = ModalWindow.open(self, "Hall of Fame — Combat Power", Vector2(760, 640))
	var entries: Array[Array] = []
	entries.append_array(MOCK_RANKING)
	entries.append([game.profile.nickname + " (you)", game.profile.level, game.stats().combat_power])
	entries.sort_custom(func(a: Array, b: Array) -> bool:
		var pa: int = a[2]
		var pb: int = b[2]
		return pa > pb)
	for i in entries.size():
		var entry: Array = entries[i]
		var name: String = entry[0]
		var row: PanelContainer = UiKit.inner_panel()
		if name.ends_with("(you)"):
			row.add_theme_stylebox_override("panel", UiKit.box(UiKit.NAVY_LIGHT, UiKit.GOLD, 12, 3))
		modal.body.add_child(row)
		var line: HBoxContainer = UiKit.hbox(14)
		row.add_child(line)
		line.add_child(UiKit.label("#%d" % (i + 1), 22, UiKit.GOLD if i < 3 else UiKit.TEXT, true))
		line.add_child(UiKit.label(name, 20))
		line.add_child(UiKit.spacer())
		line.add_child(UiKit.label("Lv %d    Power %d" % [entry[1], entry[2]], 18, UiKit.TEXT_DIM))


func _open_guild() -> void:
	var modal: ModalWindow = ModalWindow.open(self, "Guild — Skyfall Society", Vector2(820, 600))
	modal.body.add_child(UiKit.label("Preview of a future system (offline mock).", 16, UiKit.TEXT_DIM))
	var stats: Array[Array] = [["Level", "3"], ["Members", "18 / 30"], ["Wealth", "42,500"], ["Guild Blacksmith", "Lv 2 (+2% strengthen)"], ["Guild Shop", "Opens at guild level 4"]]
	for entry in stats:
		var row: HBoxContainer = UiKit.hbox()
		modal.body.add_child(row)
		var key: String = entry[0]
		var value: String = entry[1]
		row.add_child(UiKit.label(key, 20, UiKit.GOLD, true))
		row.add_child(UiKit.spacer())
		row.add_child(UiKit.label(value, 20))
	modal.body.add_child(UiKit.label("Joining, donations and guild battles arrive with the online backend.", 16, UiKit.TEXT_DIM))


func _open_settings() -> void:
	var modal: ModalWindow = ModalWindow.open(self, "Settings", Vector2(640, 460))
	modal.body.add_child(UiKit.button("Toggle fullscreen (F11)", DisplayControl.toggle_fullscreen, "blue", Vector2(400, 52)))
	modal.body.add_child(UiKit.button("Back to the start screen", func() -> void: ScreenRouter.go(self, &"boot"), "dark", Vector2(400, 52)))
	modal.body.add_child(UiKit.button("Ballistics Lab (developer)", func() -> void: ScreenRouter.go(self, &"lab"), "dark", Vector2(400, 52)))
	modal.body.add_child(UiKit.label("Save file: %s" % ProjectSettings.globalize_path(game.save_path), 14, UiKit.TEXT_DIM))
	modal.body.add_child(UiKit.label("Reset the local profile from the start screen.", 14, UiKit.TEXT_DIM))


static func _reward_text(reward: Reward) -> String:
	var parts: PackedStringArray = []
	if reward.exp > 0:
		parts.append("%d EXP" % reward.exp)
	if reward.gold > 0:
		parts.append("%d Gold" % reward.gold)
	if reward.coupons > 0:
		parts.append("%d Coupons" % reward.coupons)
	if reward.vouchers > 0:
		parts.append("%d Vouchers" % reward.vouchers)
	for entry in reward.items:
		var id: StringName = entry["id"]
		var def: ItemDefinition = ContentCatalog.shared().item(id)
		parts.append("%s x%d" % [def.display_name if def != null else String(id), DataReader.get_int(entry, "qty", 1)])
	return ", ".join(parts)


## Plaza ground drawn behind the buildings.
class _Plaza:
	extends Control

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		resized.connect(queue_redraw)

	func _draw() -> void:
		var w: float = size.x
		var h: float = size.y
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in 7:
			var x: float = w * (0.05 + i * 0.15)
			var height: float = rng.randf_range(80, 160)
			draw_rect(Rect2(x, h * 0.42 - height, 90, height), Color(0.62, 0.7, 0.92, 0.55))
			draw_colored_polygon(PackedVector2Array([Vector2(x - 8, h * 0.42 - height), Vector2(x + 45, h * 0.42 - height - 50), Vector2(x + 98, h * 0.42 - height)]), Color(0.55, 0.62, 0.88, 0.55))
		var plaza := PackedVector2Array([Vector2(0, h * 0.55), Vector2(w, h * 0.55), Vector2(w, h), Vector2(0, h)])
		draw_colored_polygon(plaza, Color(0.93, 0.85, 0.68))
		for row in 8:
			var y: float = h * 0.55 + row * (h * 0.45 / 8.0)
			draw_line(Vector2(0, y), Vector2(w, y), Color(0.82, 0.72, 0.55, 0.6), 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(w * 0.44, h * 0.55), Vector2(w * 0.56, h * 0.55), Vector2(w * 0.66, h), Vector2(w * 0.34, h)]), Color(0.86, 0.76, 0.6))
		draw_rect(Rect2(0, h * 0.52, w, h * 0.035), Color(0.5, 0.78, 0.4))
