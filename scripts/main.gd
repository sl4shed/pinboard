extends Node2D

@export var zoom_factor = 0.05
@export var max_zoom = 2.0

@onready var pin_scene: Resource = preload("res://scenes/pin.tscn")
@onready var image_scene: Resource = preload("res://scenes/image.tscn")
@onready var text_scene: Resource = preload("res://scenes/text.tscn")
@onready var camera: Camera2D = $Camera2D

@onready var pins: Node2D = $pins
@onready var images: Node2D = $images
@onready var text: Node2D = $text

var ropes = [];
var handles = [];
var connections = [];

var connection_one = null
var connection_two = null

var connecting = false
var pin_index = 0

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			camera.zoom = Vector2(zoom_factor, zoom_factor).max(camera.zoom - Vector2(zoom_factor, zoom_factor))
		elif event.button_index == MOUSE_BUTTON_WHEEL_UP:
			camera.zoom = Vector2(max_zoom, max_zoom).min(camera.zoom + Vector2(zoom_factor, zoom_factor))
	
	if event is InputEventMouseButton and event.pressed and event.double_click and event.button_index == MOUSE_BUTTON_LEFT:
		connecting = true
		var new_pin = pin_scene.instantiate()
		
		new_pin.name = "pin_%d" % pin_index
		pin_index += 1
		
		pins.add_child(new_pin)
		new_pin.position = get_global_mouse_position()
		connect_pin(new_pin)

func connect_pin(new_pin):
	if not connection_one:
		var rope = Rope.new()
		new_pin.add_child(rope)
		rope.stiffness = 0.3
		rope.rope_length = 100
		rope.num_segments = 10
		rope.line_width = 7
		rope.color = Color(1.0, 0.0, 0.0, 1.0)
		
		var line_renderer = RopeRendererLine2D.new()
		line_renderer.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		line_renderer.texture_mode = Line2D.LINE_TEXTURE_TILE
		line_renderer.target_rope_path = rope.get_path()
		line_renderer.antialiased = true
		var texture = Image.new()
		texture.load("res://assets/rope.png")
		line_renderer.texture = ImageTexture.create_from_image(texture)
		rope.add_child(line_renderer)
		
		connection_one = rope
	elif not connection_two and connection_one is Rope:
		var handle = RopeHandle.new()
		new_pin.add_child(handle)
		handle.rope_path = connection_one.get_path()
		handle.strength = 1
		
		connections.push_back({
			"rope": connection_one,
			"handle": handle
		})
		
		connection_one = null
		connection_two = null
		connecting = false

func _on_insert_id_pressed(id: int) -> void:
	match id:
		0: # insert image
			var dialog = $Camera2D/CanvasLayer/Panel/MenuBar/Insert/ImageFileDialog
			dialog.popup()
		1: # insert text
			var new_text = text_scene.instantiate()
			new_text.get_node("text").text = "Default Text"
			new_text.position = get_global_mouse_position()
			text.add_child(new_text)

func _on_file_id_pressed(id: int) -> void:
	match id:
		0: # new
			for child in pins.get_children(): child.queue_free()
			for child in images.get_children(): child.queue_free()
			for child in text.get_children(): child.queue_free()
			connections.clear()
			
			camera.global_position = Vector2(0, 0)
			camera.zoom = Vector2(1, 1)
		1: # save as
			var dialog = $Camera2D/CanvasLayer/Panel/MenuBar/File/SaveAsFileDialog
			dialog.popup()
		2: # load
			var dialog = $Camera2D/CanvasLayer/Panel/MenuBar/File/OpenFileDialog
			dialog.popup()

func _on_image_file_dialog_file_selected(path: String) -> void:
	if FileAccess.file_exists(path):
		var image = Image.new()
		image.load(path)
		var new_image = image_scene.instantiate()
		var sprite: TextureButton = new_image.get_node("border/image/texture")
		
		sprite.texture_normal = ImageTexture.create_from_image(image)
		new_image.position = get_global_mouse_position()
		images.add_child(new_image)

func _on_open_file_dialog_file_selected(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var content := file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY: return
	
	load_dict(data)

func load_dict(data: Dictionary) -> void:
	# delete everything!! hooray
	for child in pins.get_children(): child.queue_free()
	for child in images.get_children(): child.queue_free()
	for child in text.get_children(): child.queue_free()
	connections.clear()
	
	# load pins
	var loaded_pins: Dictionary = {};
	for pin in data.pins:
		var new_pin = pin_scene.instantiate()
		new_pin.name = pin.id
		pins.add_child(new_pin)
		new_pin.position = Vector2(pin.position_x, pin.position_y)
		loaded_pins[pin.id] = new_pin
	
	# connect pins
	for connection in data.connections:
		var pin_a = loaded_pins[connection.pin_a]
		var pin_b = loaded_pins[connection.pin_b]
		
		connect_pin(pin_a)
		connect_pin(pin_b)
	
	# load images
	for image in data.images:
		var image_png_buffer = Marshalls.base64_to_raw(image.image)
		var image_texture = Image.new()
		image_texture.load_png_from_buffer(image_png_buffer)
		
		var new_image = image_scene.instantiate()
		var sprite: TextureButton = new_image.get_node("border/image/texture")
		
		sprite.texture_normal = ImageTexture.create_from_image(image_texture)
		new_image.position = Vector2(image.position_x, image.position_y)
		
		images.add_child(new_image)
		new_image._on_border_color_color_changed(Color(image.border_color))
		new_image._on_bg_color_color_changed(Color(image.bg_color))
		new_image._on_size_value_changed(image.size)
		
		# set right click menu values
		new_image.get_node("Panel/VBoxContainer/Size").value = image.size
		new_image.get_node("Panel/VBoxContainer/BgColor").color = Color(image.bg_color)
		new_image.get_node("Panel/VBoxContainer/BorderColor").color = Color(image.border_color)
	
	# load text objects things
	for texto in data.text:
		var new_text = text_scene.instantiate()
		new_text.get_node("text").text = texto.text
		new_text.position = Vector2(texto.position_x, texto.position_y)
		
		text.add_child(new_text)
		
		new_text._on_size_value_changed(texto.font_size)
		new_text._on_bg_color_color_changed(Color(texto.bg_color))
		new_text._on_text_color_color_changed(Color(texto.text_color))
		
		# set right click menu values so that it's accurate
		new_text.get_node("Panel/VBoxContainer/Size").value = texto.font_size
		new_text.get_node("Panel/VBoxContainer/BgColor").color = Color(texto.bg_color)
		new_text.get_node("Panel/VBoxContainer/TextColor").color = Color(texto.text_color)
		new_text.get_node("Panel/VBoxContainer/LineEdit").text = texto.text
	
	camera.zoom = Vector2(data.camera.zoom, data.camera.zoom)
	camera.global_position = Vector2(data.camera.position_x, data.camera.position_y)

func serialize() -> Dictionary:
	var pins_array: Array = []
	var images_array: Array = []
	var text_array: Array = []
	var connections_array: Array = serialize_connections()
	
	for pin in pins.get_children(): pins_array.push_back(pin.serialize())
	for image in images.get_children(): images_array.push_back(image.serialize())
	for texto in text.get_children(): text_array.push_back(texto.serialize())
	
	return {
		"pins": pins_array,
		"images": images_array,
		"text": text_array,
		"connections": connections_array,
		"camera": camera.serialize(),
		"version": 1
	}

func serialize_connections() -> Array:
	var result := []
	for conn in connections:
		var rope = conn.rope
		var handle = conn.handle

		var pin_a = rope.get_parent() if rope else null
		var pin_b = handle.get_parent() if handle else null
		
		if pin_a and pin_b:
			result.append({
				"pin_a": pin_a.name,
				"pin_b": pin_b.name
			})
	return result

func _on_save_as_file_dialog_file_selected(path: String) -> void:
	var data = serialize()
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
