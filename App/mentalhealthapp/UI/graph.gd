extends Node2D
class_name Graph

@onready var canvas_layer = $CanvasLayer

func _ready() -> void:
	create_graph()

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
	var data = custom_data
	if not data:
		# Use mock data if no custom data provided
		data = {
			"mood_values": [3, 4, 2, 5, 4, 3, 2, 4, 5],
			"dates": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue"]
		}
	
	# Clear any existing graph
	for child in canvas_layer.get_children():
		if child.name.begins_with("Graph"):
			child.queue_free()
	
	# Create graph container
	var graph_container = VBoxContainer.new()
	graph_container.name = "GraphContainer"
	graph_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	graph_container.custom_minimum_size = Vector2(320, 480)
	
	# Set container position to be centered
	graph_container.position = Vector2(20, 20)
	canvas_layer.add_child(graph_container)
	
	# Add title
	var title = Label.new()
	title.text = "Mood Tracking"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	graph_container.add_child(title)
	
	# Add graph visualization (placeholder for actual graph)
	var graph_visual = create_visual_graph(data)
	graph_container.add_child(graph_visual)

func create_visual_graph(data):
	# This is a simplified placeholder for actual graph rendering
	# In a real implementation, you'd draw lines, points, etc.
	var panel = Panel.new()
	panel.custom_minimum_size = Vector2(320, 240)
	
	var line = Line2D.new()
	line.default_color = Color(0.2, 0.6, 1.0, 0.8)
	line.width = 2
	
	# Position points based on data
	var max_value = 5.0  # Assuming max mood value is 5
	var width = 280
	var height = 200
	var x_spacing = width / (data.mood_values.size() - 1) if data.mood_values.size() > 1 else width
	
	for i in range(data.mood_values.size()):
		var x = i * x_spacing + 20
		var y = height - (data.mood_values[i] / max_value * height) + 20
		line.add_point(Vector2(x, y))
	
	panel.add_child(line)
	
	return panel
