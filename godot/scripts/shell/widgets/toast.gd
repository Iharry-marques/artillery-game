class_name Toast
extends PanelContainer
## Short floating message ("Purchased!", "Not enough gold").

const LIFETIME: float = 2.2

var _age: float = 0.0


static func popup_text(parent: Control, text: String, good: bool = true) -> void:
	var toast := Toast.new()
	toast.add_theme_stylebox_override("panel", UiKit.box(UiKit.NAVY_DEEP, UiKit.GREEN if good else UiKit.RED, 12, 3, 6))
	toast.add_child(UiKit.label(text, 22, UiKit.TEXT, true))
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(toast)
	toast.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	toast.position.y = 96.0
	toast.reset_size.call_deferred()


func _process(delta: float) -> void:
	_age += delta
	position.x = (get_parent_area_size().x - size.x) * 0.5
	modulate.a = clampf((LIFETIME - _age) * 3.0, 0.0, 1.0)
	if _age >= LIFETIME:
		queue_free()
