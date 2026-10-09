extends ShellScreen
## The Blacksmith: Strengthen (fully working, the core sink), Compose, Fuse and
## Transfer. Odds and costs are REFERENCE ESTIMATES (EnhancementRules); no real money.

const TABS: Array[String] = ["Strengthen", "Compose", "Fuse", "Transfer"]
const STONE_IDS: Array[StringName] = [&"stone_1", &"stone_2", &"stone_3", &"stone_4"]
const ELEMENT_IDS: Array[StringName] = [&"elem_attack", &"elem_defense", &"elem_agility", &"elem_luck"]

var _tab: int = 0
var _selected_uid: int = -1
var _transfer_target: int = -1
var _stones: Array[StringName] = []
var _use_charm: bool = false
var _use_guard: bool = false
var _result_text: String = ""
var _result_good: bool = true
var _list: VBoxContainer
var _work: VBoxContainer
var _tab_buttons: Array[Button] = []


func screen_title() -> String:
	return "Blacksmith"


func _style_backdrop(backdrop: ScreenBackdrop) -> void:
	backdrop.top_color = Color(0.35, 0.22, 0.32)
	backdrop.bottom_color = Color(0.95, 0.6, 0.35)
	backdrop.hill_color = Color(0.45, 0.3, 0.3)


func build() -> void:
	var column: VBoxContainer = UiKit.vbox(12)
	content_root.add_child(column)
	var tabs: HBoxContainer = UiKit.hbox(8)
	column.add_child(tabs)
	for i in TABS.size():
		var tab_button: Button = UiKit.button(TABS[i], func() -> void: _set_tab(i), "dark", Vector2(180, 52))
		tabs.add_child(tab_button)
		_tab_buttons.append(tab_button)
	var row: HBoxContainer = UiKit.hbox(20)
	row.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(row)
	var list_panel: PanelContainer = UiKit.panel()
	list_panel.custom_minimum_size = Vector2(470, 0)
	row.add_child(list_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_panel.add_child(scroll)
	_list = UiKit.vbox(8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	var work_panel: PanelContainer = UiKit.panel(Color(0.16, 0.12, 0.2), UiKit.GOLD)
	work_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(work_panel)
	_work = UiKit.vbox(14)
	work_panel.add_child(_work)
	refresh()


func refresh() -> void:
	for i in _tab_buttons.size():
		UiKit.tint(_tab_buttons[i], "primary" if i == _tab else "dark")
	for child in _list.get_children():
		child.queue_free()
	for child in _work.get_children():
		child.queue_free()
	match _tab:
		0:
			_build_list(func(def: ItemDefinition) -> bool: return def.can_strengthen(), "Pick equipment to strengthen")
			_build_strengthen()
		1:
			_build_list(func(def: ItemDefinition) -> bool: return def.is_equipment(), "Pick equipment to compose")
			_build_compose()
		2:
			_build_fuse()
		3:
			_build_list(func(def: ItemDefinition) -> bool: return def.can_strengthen(), "Pick the SOURCE item")
			_build_transfer()
	refresh_top_bar()


func _set_tab(tab: int) -> void:
	_tab = tab
	_result_text = ""
	_stones.clear()
	refresh()


func _equipment_items() -> Array[ItemInstance]:
	var items: Array[ItemInstance] = game.profile.equipment.all_items()
	items.append_array(game.profile.inventory.items)
	return items


func _build_list(filter: Callable, title: String) -> void:
	_list.add_child(UiKit.label(title, 22, UiKit.GOLD, true))
	for item in _equipment_items():
		var def: ItemDefinition = game.content.item(item.def_id)
		var keep: bool = filter.call(def)
		if not keep:
			continue
		var row: HBoxContainer = UiKit.hbox(10)
		_list.add_child(row)
		var cell: ItemSlot = ItemSlot.create(72)
		cell.show_item(def, item)
		cell.button_pressed = item.uid == _selected_uid
		var uid: int = item.uid
		cell.pressed.connect(func() -> void:
			_selected_uid = uid
			_result_text = ""
			refresh())
		row.add_child(cell)
		var label: String = "%s%s%s" % [def.display_name, " +%d" % item.enhance_level if item.enhance_level > 0 else "", "  (equipped)" if game.profile.is_equipped(uid) else ""]
		row.add_child(UiKit.label(label, 18, UiKit.rarity_color(def.rarity)))


func _selected() -> ItemInstance:
	return game.profile.find_item(_selected_uid)


func _item_header(item: ItemInstance) -> void:
	var def: ItemDefinition = game.content.item(item.def_id)
	var header: HBoxContainer = UiKit.hbox(16)
	_work.add_child(header)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(120, 120)
	icon.set_item(def, 1, item.enhance_level)
	header.add_child(icon)
	var text: VBoxContainer = UiKit.vbox(4)
	header.add_child(text)
	text.add_child(UiKit.label("%s +%d" % [def.display_name, item.enhance_level], 28, UiKit.rarity_color(def.rarity), true))
	text.add_child(UiKit.label(", ".join(UiKit.stat_lines(CharacterStats.item_stats(def, item))), 18, UiKit.GREEN))
	if not item.composed.is_zero():
		text.add_child(UiKit.label("Composed: " + ", ".join(UiKit.stat_lines(item.composed)), 16, UiKit.GOLD))


func _result_banner() -> void:
	if _result_text != "":
		var label: Label = UiKit.label(_result_text, 30, UiKit.GREEN if _result_good else UiKit.RED, true)
		label.add_theme_constant_override("outline_size", 8)
		_work.add_child(label)


# --- Strengthen -------------------------------------------------------------------------


func _build_strengthen() -> void:
	var item: ItemInstance = _selected()
	if item == null or not game.content.item(item.def_id).can_strengthen():
		_work.add_child(UiKit.label("Strengthen", 34, UiKit.GOLD, true))
		_work.add_child(UiKit.label("Choose a weapon, clothes or hat on the left.\nAdd up to 3 Strengthen Stones, optionally a Lucky Charm\n(+15%) and a Guardian Seal (no level loss on failure).", 20))
		return
	_item_header(item)
	_work.add_child(UiKit.label("Stones (up to %d):" % EnhancementRules.MAX_STONES, 20, UiKit.TEXT, true))
	var slots: HBoxContainer = UiKit.hbox(10)
	_work.add_child(slots)
	for i in EnhancementRules.MAX_STONES:
		var cell: ItemSlot = ItemSlot.create(80)
		cell.caption = "empty"
		if i < _stones.size():
			cell.show_item(game.content.item(_stones[i]), null)
		else:
			cell.clear_item()
		var index: int = i
		cell.pressed.connect(func() -> void:
			if index < _stones.size():
				_stones.remove_at(index)
			refresh())
		slots.add_child(cell)
	var picker: HBoxContainer = UiKit.hbox(8)
	_work.add_child(picker)
	for stone_id in STONE_IDS:
		var owned: int = game.profile.inventory.count(stone_id) - _stones.count(stone_id)
		var add: Button = UiKit.button("+ Lv%d (%d)" % [game.content.item(stone_id).stone_level, owned], func() -> void:
			if _stones.size() < EnhancementRules.MAX_STONES:
				_stones.append(stone_id)
			refresh(), "blue", Vector2(140, 46))
		add.disabled = owned <= 0 or _stones.size() >= EnhancementRules.MAX_STONES
		picker.add_child(add)
	var toggles: HBoxContainer = UiKit.hbox(20)
	_work.add_child(toggles)
	toggles.add_child(_toggle("Lucky Charm (+15%%)  x%d" % game.profile.inventory.count(&"charm_luck"), _use_charm, game.profile.inventory.count(&"charm_luck") > 0, func(on: bool) -> void:
		_use_charm = on
		refresh()))
	toggles.add_child(_toggle("Guardian Seal  x%d" % game.profile.inventory.count(&"charm_guard"), _use_guard, game.profile.inventory.count(&"charm_guard") > 0, func(on: bool) -> void:
		_use_guard = on
		refresh()))
	var preview: Blacksmith.Preview = Blacksmith.preview_strengthen(game.profile, game.content, item.uid, _stones, _use_charm, _use_guard)
	var stats_row: HBoxContainer = UiKit.hbox(40)
	_work.add_child(stats_row)
	var chance: Label = UiKit.label("%d%%" % roundi(preview.chance * 100.0), 64, UiKit.GOLD if preview.chance >= 0.5 else UiKit.ORANGE, true)
	chance.add_theme_constant_override("outline_size", 10)
	stats_row.add_child(chance)
	var info: VBoxContainer = UiKit.vbox(2)
	stats_row.add_child(info)
	info.add_child(UiKit.label("Success chance → +%d" % preview.next_level, 20))
	info.add_child(UiKit.label("Cost: %d Gold" % preview.cost, 20, UiKit.GOLD))
	info.add_child(UiKit.label("On success: " + ", ".join(UiKit.stat_lines(preview.gain)), 18, UiKit.GREEN))
	info.add_child(UiKit.label("On failure: %s" % ("item drops to +%d!" % (item.enhance_level - 1) if preview.drops_on_failure else "level kept"), 18, UiKit.RED if preview.drops_on_failure else UiKit.TEXT_DIM))
	var go: Button = UiKit.button("STRENGTHEN", func() -> void:
		var outcome: Blacksmith.Outcome = game.strengthen(item.uid, _stones, _use_charm, _use_guard)
		_result_text = outcome.message
		_result_good = outcome.success
		_stones.clear()
		_use_charm = false
		_use_guard = false
		refresh(), "primary", Vector2(420, 70))
	go.disabled = preview.error != ""
	_work.add_child(go)
	if preview.error != "":
		_work.add_child(UiKit.label(preview.error, 18, UiKit.TEXT_DIM))
	_result_banner()


func _toggle(text: String, on: bool, enabled: bool, changed: Callable) -> CheckBox:
	var box := CheckBox.new()
	box.text = text
	box.button_pressed = on and enabled
	box.disabled = not enabled
	box.add_theme_font_size_override("font_size", 18)
	box.toggled.connect(changed)
	return box


# --- Compose / Fuse / Transfer ----------------------------------------------------------


func _build_compose() -> void:
	_work.add_child(UiKit.label("Compose", 34, UiKit.GOLD, true))
	var item: ItemInstance = _selected()
	if item == null:
		_work.add_child(UiKit.label("Choose any equipment. Element stones add +%d to one\nattribute (cap +%d each). %d Gold per stone." % [Blacksmith.COMPOSE_POINTS, Blacksmith.COMPOSE_CAP, Blacksmith.COMPOSE_GOLD], 20))
		return
	_item_header(item)
	var row: HBoxContainer = UiKit.hbox(10)
	_work.add_child(row)
	for element_id in ELEMENT_IDS:
		var def: ItemDefinition = game.content.item(element_id)
		var count: int = game.profile.inventory.count(element_id)
		var button: Button = UiKit.button("%s\n(%d)" % [def.display_name, count], func() -> void:
			var outcome: Blacksmith.Outcome = game.compose(item.uid, element_id)
			_result_text = outcome.message
			_result_good = outcome.ok
			refresh(), "blue", Vector2(170, 80))
		button.disabled = count <= 0
		row.add_child(button)
	_result_banner()


func _build_fuse() -> void:
	_list.add_child(UiKit.label("Your stones", 22, UiKit.GOLD, true))
	for stone_id in STONE_IDS:
		var row: HBoxContainer = UiKit.hbox(10)
		_list.add_child(row)
		var icon := ItemIcon.new()
		icon.custom_minimum_size = Vector2(64, 64)
		icon.set_item(game.content.item(stone_id), game.profile.inventory.count(stone_id))
		row.add_child(icon)
		row.add_child(UiKit.label("%s  x%d" % [game.content.item(stone_id).display_name, game.profile.inventory.count(stone_id)], 18))
	_work.add_child(UiKit.label("Fuse", 34, UiKit.GOLD, true))
	_work.add_child(UiKit.label("Combine %d stones into 1 of the next level. Success %d%%; a failure\ndestroys the stones." % [Blacksmith.FUSE_INPUT, roundi(Blacksmith.FUSE_CHANCE * 100)], 20))
	var row_buttons: HBoxContainer = UiKit.hbox(12)
	_work.add_child(row_buttons)
	for level in range(1, 4):
		var button: Button = UiKit.button("4 x Lv%d → Lv%d\n%d Gold" % [level, level + 1, Blacksmith.fuse_cost(level)], func() -> void:
			var outcome: Blacksmith.Outcome = game.fuse(level)
			_result_text = outcome.message
			_result_good = outcome.success
			refresh(), "primary", Vector2(210, 84))
		button.disabled = game.profile.inventory.count(StringName("stone_%d" % level)) < Blacksmith.FUSE_INPUT
		row_buttons.add_child(button)
	_result_banner()


func _build_transfer() -> void:
	_work.add_child(UiKit.label("Transfer", 34, UiKit.GOLD, true))
	var source: ItemInstance = _selected()
	if source == null:
		_work.add_child(UiKit.label("Move a strengthening level to a new item of the same type.\nThe source returns to +0. Cost: %d Gold." % Blacksmith.TRANSFER_GOLD, 20))
		return
	_item_header(source)
	_work.add_child(UiKit.label("Pick the TARGET:", 20, UiKit.TEXT, true))
	var source_def: ItemDefinition = game.content.item(source.def_id)
	var row: HBoxContainer = UiKit.hbox(10)
	_work.add_child(row)
	for item in _equipment_items():
		var def: ItemDefinition = game.content.item(item.def_id)
		if item.uid == source.uid or def.slot() != source_def.slot():
			continue
		var cell: ItemSlot = ItemSlot.create(80)
		cell.show_item(def, item)
		cell.button_pressed = item.uid == _transfer_target
		var uid: int = item.uid
		cell.pressed.connect(func() -> void:
			_transfer_target = uid
			refresh())
		row.add_child(cell)
	var go: Button = UiKit.button("TRANSFER", func() -> void:
		var outcome: Blacksmith.Outcome = game.transfer(source.uid, _transfer_target)
		_result_text = outcome.message
		_result_good = outcome.ok
		refresh(), "primary", Vector2(360, 64))
	go.disabled = _transfer_target < 0
	_work.add_child(go)
	_result_banner()
