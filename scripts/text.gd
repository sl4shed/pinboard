extends Node2D

@onready var ui = $Panel
@onready var text = $text

var offset = 0
var pressed = false

@onready var main_node = get_tree().root.get_node("main")
@onready var camera = main_node.get_node("Camera2D")

var bg_color: Color = Color(1, 1, 1)
var text_color: Color = Color(0, 0, 0)
var font_size = 16

func _process(delta: float) -> void:
	offset = get_global_mouse_position() - global_position
	if ui.visible: ui.scale = Vector2(1 / camera.zoom.x, 1 / camera.zoom.y)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_LEFT and pressed:
		global_position = get_global_mouse_position() - offset
		ui.visible = false
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and pressed:
		ui.visible = !ui.visible
		ui.position = get_global_mouse_position() - global_position

func _on_button_button_down() -> void:
	pressed = true

func _on_button_button_up() -> void:
	pressed = false

func _on_bg_color_color_changed(color: Color) -> void:
	var stylebox = text.get_theme_stylebox("normal")
	stylebox.bg_color = color
	text.add_theme_stylebox_override("normal", stylebox)
	
	stylebox = text.get_theme_stylebox("pressed")
	stylebox.bg_color = color
	text.add_theme_stylebox_override("pressed", stylebox)
	
	stylebox = text.get_theme_stylebox("hover")
	stylebox.bg_color = color
	text.add_theme_stylebox_override("hover", stylebox)
	bg_color = color

func _on_text_color_color_changed(color: Color) -> void:
	text.add_theme_color_override("font_color", color)
	text.add_theme_color_override("font_focus_color", color)
	text.add_theme_color_override("font_pressed_color", color)
	text.add_theme_color_override("font_hover_color", color)
	text.add_theme_color_override("font_hover_pressed_color", color)
	text_color = color

func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text.is_empty(): return
	text.text = new_text

func _on_size_value_changed(size: float) -> void:
	text.add_theme_font_size_override("font_size", size)
	font_size = size

func _on_delete_pressed() -> void:
	queue_free()

func serialize() -> Dictionary:
	return {
		"type": "text",
		"position_x": global_position.x,
		"position_y": global_position.y,
		"text": text.text,
		"bg_color": bg_color.to_html(),
		"text_color": text_color.to_html(),
		"font_size": font_size,
	}
