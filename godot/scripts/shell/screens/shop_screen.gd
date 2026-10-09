extends ShellScreen
## The Shop: categories, item cards with prices in local test currencies, details
## and buying (items go straight to the Bag). No real payments.

var _category: int = 0
var _selected: ShopListing
var _count: int = 1
var _grid: GridContainer
var _details: VBoxContainer
var _tab_buttons: Array[Button] = []


func screen_title() -> String:
	return "Shop"


func build() -> void:
	var row: HBoxContainer = UiKit.hbox(20)
	content_root.add_child(row)
	var left: PanelContainer = UiKit.panel()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var column: VBoxContainer = UiKit.vbox(12)
	left.add_child(column)
	var tabs: HBoxContainer = UiKit.hbox(8)
	column.add_child(tabs)
	for i in 4:
		var tab_button: Button = UiKit.button(ShopListing.category_name(i), func() -> void: _set_category(i), "dark", Vector2(170, 48))
		tabs.add_child(tab_button)
		_tab_buttons.append(tab_button)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 3
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	var right: PanelContainer = UiKit.panel()
	right.custom_minimum_size = Vector2(420, 0)
	row.add_child(right)
	_details = UiKit.vbox(12)
	right.add_child(_details)
	refresh()


func refresh() -> void:
	for i in _tab_buttons.size():
		UiKit.tint(_tab_buttons[i], "primary" if i == _category else "dark")
	for child in _grid.get_children():
		child.queue_free()
	for listing in game.content.shop:
		if listing.category != _category:
			continue
		_grid.add_child(_card(listing))
	_show_details()
	refresh_top_bar()


func _card(listing: ShopListing) -> Control:
	var def: ItemDefinition = game.content.item(listing.item_id)
	var card := Button.new()
	card.custom_minimum_size = Vector2(300, 120)
	card.toggle_mode = true
	card.button_pressed = listing == _selected
	card.add_theme_stylebox_override("normal", UiKit.box(UiKit.NAVY_LIGHT, Color(1, 1, 1, 0.12), 12, 2))
	card.add_theme_stylebox_override("hover", UiKit.box(UiKit.NAVY_LIGHT.lightened(0.1), UiKit.SKY, 12, 2))
	card.add_theme_stylebox_override("pressed", UiKit.box(UiKit.NAVY_LIGHT, UiKit.GOLD, 12, 3))
	card.pressed.connect(func() -> void:
		_selected = listing
		_count = 1
		refresh())
	var line: HBoxContainer = UiKit.hbox(10)
	line.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	line.offset_left = 10
	line.offset_top = 10
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(line)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(96, 96)
	icon.set_item(def, listing.quantity)
	line.add_child(icon)
	var text: VBoxContainer = UiKit.vbox(4)
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	line.add_child(text)
	text.add_child(UiKit.label(def.display_name, 18, UiKit.rarity_color(def.rarity), true))
	text.add_child(UiKit.label("x%d" % listing.quantity if listing.quantity > 1 else ItemDefinition.kind_name(def.kind), 15, UiKit.TEXT_DIM))
	text.add_child(UiKit.label("%d %s" % [listing.price, CurrencyWallet.currency_name(listing.currency)], 20, UiKit.currency_color(listing.currency), true))
	return card


func _show_details() -> void:
	for child in _details.get_children():
		child.queue_free()
	if _selected == null:
		_details.add_child(UiKit.label("Pick an item", 24, UiKit.TEXT_DIM))
		_details.add_child(UiKit.label("Gold, Coupons and Vouchers are local test\ncurrencies. No real payments exist.", 16, UiKit.TEXT_DIM))
		return
	var def: ItemDefinition = game.content.item(_selected.item_id)
	var icon := ItemIcon.new()
	icon.custom_minimum_size = Vector2(150, 150)
	icon.set_item(def, _selected.quantity)
	_details.add_child(icon)
	_details.add_child(UiKit.label(def.display_name, 26, UiKit.rarity_color(def.rarity), true))
	var description: Label = UiKit.label(def.description, 16)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size = Vector2(380, 0)
	_details.add_child(description)
	var lines: PackedStringArray = UiKit.stat_lines(def.stats)
	if not lines.is_empty():
		_details.add_child(UiKit.label("\n".join(lines), 18, UiKit.GREEN))
	if def.kind == ItemDefinition.Kind.WEAPON:
		_details.add_child(UiKit.label("%s   Angles %d-%d°   Crater %.2f u" % [def.weapon_style, def.min_angle, def.max_angle, def.crater_radius], 16, UiKit.TEXT_DIM))
	var count_row: HBoxContainer = UiKit.hbox(10)
	_details.add_child(count_row)
	if def.is_stackable():
		count_row.add_child(UiKit.button("−", func() -> void:
			_count = maxi(1, _count - 1)
			refresh(), "dark", Vector2(56, 48)))
		count_row.add_child(UiKit.label("x%d" % _count, 24, UiKit.TEXT, true))
		count_row.add_child(UiKit.button("+", func() -> void:
			_count = mini(20, _count + 1)
			refresh(), "dark", Vector2(56, 48)))
	var total: int = _selected.price * _count
	_details.add_child(UiKit.label("Total: %d %s" % [total, CurrencyWallet.currency_name(_selected.currency)], 24, UiKit.currency_color(_selected.currency), true))
	_details.add_child(UiKit.label("You have %d" % game.profile.wallet.balance(_selected.currency), 16, UiKit.TEXT_DIM))
	var buy: Button = UiKit.button("BUY", func() -> void:
		var error: String = game.buy(_selected, _count)
		toast("Purchased %s!" % def.display_name if error == "" else error, error == "")
		refresh(), "green", Vector2(380, 64))
	buy.disabled = not game.profile.wallet.can_afford(_selected.currency, total)
	_details.add_child(buy)


func _set_category(category: int) -> void:
	_category = category
	_selected = null
	refresh()
