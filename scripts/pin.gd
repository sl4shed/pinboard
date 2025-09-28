extends Node2D

@onready var ui = $Panel
@onready var main_node = get_tree().root.get_node("main")
@onready var camera = main_node.get_node("Camera2D")

func _on_toggle_pressed() -> void:
	ui.visible = !ui.visible
	ui.position = get_global_mouse_position() - global_position
	
	if main_node.connection_one and main_node.connection_one is Rope:
		$"Panel/VBoxContainer/Add Connection".visible = false
		$"Panel/VBoxContainer/Connect To".visible = true
	else: # not connecting
		$"Panel/VBoxContainer/Add Connection".visible = true
		$"Panel/VBoxContainer/Connect To".visible = false

func _on_add_connection_pressed() -> void:
	var rope = Rope.new()
	add_child(rope)
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
	
	main_node.connection_one = rope
	main_node.connecting = true
	ui.visible = false

func _on_connect_to_pressed() -> void:
	if not main_node.connection_one: 
		main_node.connection_one = null
		return
	
	var handle = RopeHandle.new()
	add_child(handle)
	handle.rope_path = main_node.connection_one.get_path()
	handle.strength = 1
	
	main_node.connections.push_back({
			"rope": main_node.connection_one,
			"handle": handle
	})
	
	main_node.connection_one = null
	main_node.connection_two = null
	ui.visible = false

func _on_delete_pressed() -> void:
	queue_free()
	
	var rope_handles = [];
	var ropes = [];
	
	for child in get_children():
		if child is RopeHandle or child is Marker2D: rope_handles.push_back(child)
		if child is Rope: ropes.push_back(child)
	
	var rope_deletes = [];
	var handle_deletes = []
	
	var connections_to_remove = []
	for connection in main_node.connections:
		if ropes.has(connection.rope) or rope_handles.has(connection.handle) or ropes.has(get_node(connection.handle.rope_path)):
			if not handle_deletes.has(connection.handle): handle_deletes.push_back(connection.handle)
			if not rope_deletes.has(connection.rope): rope_deletes.push_back(connection.rope)
			if connection.handle and connection.handle.rope_path:
				var second_rope = get_node(connection.handle.rope_path)
				if not rope_deletes.has(second_rope): rope_deletes.push_back(second_rope)
			
			connections_to_remove.push_back(connection)
	
	for connection in connections_to_remove:
		main_node.connections.remove_at(main_node.connections.find(connection))
	for handle in handle_deletes: if handle: handle.queue_free()
	for rope in rope_deletes: if rope: rope.queue_free()

func _process(_delta: float) -> void:
	# scale ui to camera
	if ui.visible: ui.scale = Vector2(1 / camera.zoom.x, 1 / camera.zoom.y)

func serialize() -> Dictionary:
	return {
		"type": "pin",
		"position_x": global_position.x,
		"position_y": global_position.y,
		"id": name
	}
