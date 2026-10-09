class_name TopBar
extends PanelContainer
## Screen header: back button, title, player chip and the three currencies.

signal back_pressed

var _currencies: Label
var _player: Label


func setup(title: String, show_back: bool = true, back_label: String = "City") -> void:
	add_theme_stylebox_override("panel", UiKit.box(UiKit.NAVY_DEEP, UiKit.GOLD, 0, 0))
	set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	custom_minimum_size = Vector2(0, 72)
	var row: HBoxContainer = UiKit.hbox(18)
	add_child(row)
	if show_back:
		row.add_child(UiKit.button("◀  " + back_label, func() -> void: back_pressed.emit(), "blue", Vector2(140, 48)))
	row.add_child(UiKit.label(title, 30, UiKit.GOLD, true))
	row.add_child(UiKit.spacer())
	_player = UiKit.label("", 18, UiKit.TEXT)
	row.add_child(_player)
	_currencies = UiKit.label("", 18, UiKit.TEXT)
	row.add_child(_currencies)
	refresh()


func refresh() -> void:
	var game: GameSession = GameSession.get_instance()
	if not game.has_profile():
		return
	var p: PlayerProfile = game.profile
	_player.text = "%s  Lv %d" % [p.nickname, p.level]
	_currencies.text = "●  Gold %s     ◆  Coupons %s     ✦  Vouchers %s" % [_format(p.wallet.gold), _format(p.wallet.coupons), _format(p.wallet.vouchers)]


static func _format(value: int) -> String:
	var text: String = str(absi(value))
	var out: String = ""
	while text.length() > 3:
		out = "," + text.right(3) + out
		text = text.left(text.length() - 3)
	return ("-" if value < 0 else "") + text + out
