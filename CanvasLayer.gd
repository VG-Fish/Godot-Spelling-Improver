extends CanvasLayer


# Called when the node enters the scene tree for the first time.
func _ready():
	get_window().mode = Window.MODE_FULLSCREEN
	# Default to user size
	get_viewport().size = DisplayServer.screen_get_size()
	get_window().position = Vector2i(0, 0)
