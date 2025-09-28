extends Node2D

@onready var border = $border
@onready var image = $border/image
@onready var texture = $border/image/texture

@onready var size_ui = $Panel/VBoxContainer/Size
@onready var bg_color_ui = $Panel/VBoxContainer/BgColor
@onready var bd_color_ui = $Panel/VBoxContainer/BorderColor
@onready var ui = $Panel

@onready var main_node = get_tree().root.get_node("main")
@onready var camera = main_node.get_node("Camera2D")

var pressed = false
var speed = 0.1
@onready var offset = get_global_mouse_position() - global_position

var initial_x = 0
var initial_y = 0

var border_color: Color = Color(1, 1, 1)
var bg_color: Color = Color(0, 0, 0)
var size: float = 1

func _ready():
	texture.size.x = texture.get_texture_normal().get_width()
	texture.size.y = texture.get_texture_normal().get_height()
	initial_x = texture.get_texture_normal().get_width()
	initial_y = texture.get_texture_normal().get_height()
	
	image.custom_minimum_size = texture.size
	border.custom_minimum_size = texture.size + Vector2(10, 10)

func _process(_delta):
	offset = get_global_mouse_position() - global_position
	if ui.visible: ui.scale = Vector2(1 / camera.zoom.x, 1 / camera.zoom.y)

func _input(event: InputEvent):
	if event is InputEventMouse and pressed and event.button_mask == MOUSE_BUTTON_LEFT:
		global_position = get_global_mouse_position() - offset
		ui.visible = false

func _on_texture_button_down() -> void:
	pressed = true

func _on_texture_button_up() -> void:
	pressed = false

func _on_delete_pressed() -> void:
	queue_free()

func _on_size_value_changed(value: float) -> void:
	texture.size = Vector2(initial_x * value, initial_y * value)
	image.custom_minimum_size = texture.size
	border.custom_minimum_size = texture.size + Vector2(10, 10)
	size = value

func _on_texture_pressed() -> void:
	if Input.is_action_pressed("right_click"):
		ui.position = get_global_mouse_position() - global_position
		ui.visible = !ui.visible

func _on_bg_color_color_changed(color: Color) -> void:
	var old_stylebox = image.get_theme_stylebox("panel").duplicate()
	old_stylebox.bg_color = color
	image.add_theme_stylebox_override("panel", old_stylebox)
	bg_color = color

func _on_border_color_color_changed(color: Color) -> void:
	var old_stylebox = border.get_theme_stylebox("panel").duplicate()
	old_stylebox.bg_color = color
	border.add_theme_stylebox_override("panel", old_stylebox)
	border_color = color

func serialize() -> Dictionary:
	var tex: Texture2D = texture.texture_normal
	
	var base64_data = ""
	if tex and tex is Texture2D:
		var img: Image = tex.get_image()
		if img:
			var bytes: PackedByteArray = img.save_png_to_buffer()
			base64_data = Marshalls.raw_to_base64(bytes)
	
	return {
		"type": "image",
		"position_x": global_position.x,
		"position_y": global_position.y,
		"bg_color": bg_color.to_html(),
		"border_color": border_color.to_html(),
		"size": size,
		"image": base64_data
	}
