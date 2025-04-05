extends Node2D
class_name Graph

@onready var canvas_layer = $CanvasLayer

func _ready() -> void:
	pass

func _process(delta) -> void: # called every frame
	pass

func load_json_file(file_path):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			return json.data
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())
	else:
		print("Could not open file: ", file_path)
	
	return null

func create_graph(custom_data = null):
	var data = load_json_file("res://Utility/") if custom_data else null
	# Implement your graph creation logic here using the JSON data
	# For example:
	# - Create Line2D nodes for line graphs
	# - Position nodes according to data values
