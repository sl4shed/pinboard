extends Camera2D

func serialize() -> Dictionary:
	return {
		"type": "camera",
		"position_x": global_position.x,
		"position_y": global_position.y,
		"zoom": zoom.x
	}

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and event.button_mask == MOUSE_BUTTON_MASK_MIDDLE:
		position -= event.relative / zoom
