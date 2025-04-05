extends Node
# Globally loaded

func SetDisplay():
	var view_port = get_node("/root").get_child(1).get_viewport_rect().size
	var camera = get_node("/root").get_child(1).find_node("Camera2D")
	print(camera.name)
	var view_port_scale = 600/view_port.x
	camera.set_zoom(camera.get_zoom() * view_port_scale)
	print(camera.zoom)

func generate_random_inputs():
	# Returns a usable output such that it can be graphed as a json
	# Used on the homepage to propogate the graph without needing to do work
	pass
