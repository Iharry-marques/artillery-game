class_name ModalWindow
extends Control
## Dimmed overlay with a framed window (Quests, Mail, Friends...). Content goes in `body`.

signal closed

var body: VBoxContainer
var _title: Label


static func open(parent: Control, title: String, window_size: Vector2 = Vector2(900, 620)) -> ModalWindow:
	var modal := ModalWindow.new()
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.03, 0.08, 0.6)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(dim)
	var frame: PanelContainer = UiKit.panel()
	frame.custom_minimum_size = window_size
	frame.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	frame.position = -window_size * 0.5
	frame.size = window_size
	modal.add_child(frame)
	var column: VBoxContainer = UiKit.vbox(12)
	frame.add_child(column)
	var header: HBoxContainer = UiKit.hbox()
	column.add_child(header)
	modal._title = UiKit.label(title, 30, UiKit.GOLD, true)
	header.add_child(modal._title)
	header.add_child(UiKit.spacer())
	header.add_child(UiKit.button("✕", modal.close, "red", Vector2(56, 48)))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	modal.body = UiKit.vbox(10)
	modal.body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(modal.body)
	return modal


func close() -> void:
	closed.emit()
	queue_free()


func clear_body() -> void:
	for child in body.get_children():
		child.queue_free()
