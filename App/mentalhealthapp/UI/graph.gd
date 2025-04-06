extends Node2D
class_name Graph

@onready var canvas_layer = $CanvasLayer
@onready var graph_container = $CanvasLayer/GraphContainer

# Colors for the graph
const BACKGROUND_COLOR = Color("#474747")
const LINE_COLOR = Color("#4285F4")
const POINT_COLOR = Color("#DB4437")
const GRID_COLOR = Color("#9AA0A6")

func _ready() -> void:
	DataStorage.connect("data_updated", Callable(self, "_on_data_updated"))
	create_graph()

func _process(delta) -> void:
	pass

func _on_data_updated():
	create_graph()

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
	for child in graph_container.get_children():
		child.queue_free()
	
	var title = Label.new()
	title.text = "Mood Tracking"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	graph_container.add_child(title)
	
	var data = get_graph_data()
	if data.mood_values.size() == 0:
		# Use mock data if no entries in storage
		data = {
			"mood_values": [3, 4, 2, 5, 4, 3, 2, 4, 5],
			"dates": ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun", "Mon", "Tue"]
		}
	
	var graph_visual = create_visual_graph(data)
	graph_container.add_child(graph_visual)
	add_summary_statistics(data)

func get_graph_data():
	var data = {
		"mood_values": [],
		"dates": []
	}
	
	# If we have mood scores in storage, use them
	if DataStorage.user_data.has("mood_scores") and DataStorage.user_data.mood_scores.size() > 0:
		# Get the last 10 entries (or fewer if less available)
		var entries_to_show = min(10, DataStorage.user_data.mood_scores.size())
		var start_index = max(0, DataStorage.user_data.mood_scores.size() - entries_to_show)
		
		for i in range(start_index, DataStorage.user_data.mood_scores.size()):
			var entry = DataStorage.user_data.mood_scores[i]
			data.mood_values.append(entry.score)
			
			# Convert timestamp to readable date
			var datetime = Time.get_datetime_dict_from_unix_time(entry.timestamp)
			var day_names = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
			var day_name = day_names[datetime.weekday]
			data.dates.append(day_name)
	
	return data

func create_visual_graph(data):
	var graph_rect = ColorRect.new()
	graph_rect.color = BACKGROUND_COLOR
	graph_rect.custom_minimum_size = Vector2(320, 200)
	graph_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Create a Control node to draw the graph
	var graph_draw = Control.new()
	graph_draw.custom_minimum_size = Vector2(320, 200)
	graph_draw.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	graph_draw.connect("draw", Callable(self, "_draw_graph").bind(graph_draw, data))
	graph_rect.add_child(graph_draw)
	
	return graph_rect

func _draw_graph(control, data):
	var size = control.size
	var padding = Vector2(30, 30)
	var graph_width = size.x - padding.x * 2
	var graph_height = size.y - padding.y * 2
	
	var values = data.mood_values
	var labels = data.dates
	
	if values.size() == 0:
		return
	
	var min_value = values.min()
	var max_value = values.max()

	if max_value == min_value:
		min_value = max(0, min_value - 1)
		max_value = min_value + 2
	
	# Draw axes
	var axis_color = GRID_COLOR
	control.draw_line(Vector2(padding.x, padding.y), Vector2(padding.x, size.y - padding.y), axis_color)
	control.draw_line(Vector2(padding.x, size.y - padding.y), Vector2(size.x - padding.x, size.y - padding.y), axis_color)
	
	# Calculate scale factors
	var y_scale = graph_height / float(max_value - min_value)
	var x_scale = graph_width / float(max(1, values.size() - 1))
	
	# Draw horizontal grid lines and y-axis labels
	var grid_steps = 5
	for i in range(grid_steps + 1):
		var y_value = min_value + (max_value - min_value) * i / grid_steps
		var y_pos = size.y - padding.y - (y_value - min_value) * y_scale
		
		# Grid line
		control.draw_line(Vector2(padding.x, y_pos), Vector2(size.x - padding.x, y_pos), GRID_COLOR.darkened(0.7), 0.5, true)

		var label = str(int(y_value))
		var font = control.get_theme_default_font()
		var font_size = control.get_theme_default_font_size()
		control.draw_string(font, Vector2(padding.x - 20, y_pos + 5), label, HORIZONTAL_ALIGNMENT_RIGHT, -1, font_size)
	
	for i in range(values.size()):
		if i % max(1, values.size() / 5) == 0 or i == values.size() - 1:  # Show fewer labels if we have many points
			var x_pos = padding.x + i * x_scale
			var label = labels[i]
			var font = control.get_theme_default_font()
			var font_size = control.get_theme_default_font_size()
			control.draw_string(font, Vector2(x_pos - 10, size.y - padding.y + 15), label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	
	# Draw line graph and points
	for i in range(values.size() - 1):
		var start_x = padding.x + i * x_scale
		var start_y = size.y - padding.y - (values[i] - min_value) * y_scale
		var end_x = padding.x + (i + 1) * x_scale
		var end_y = size.y - padding.y - (values[i + 1] - min_value) * y_scale
		control.draw_line(Vector2(start_x, start_y), Vector2(end_x, end_y), LINE_COLOR, 2.0)
	
	# Draw points
	for i in range(values.size()):
		var x_pos = padding.x + i * x_scale
		var y_pos = size.y - padding.y - (values[i] - min_value) * y_scale
		control.draw_circle(Vector2(x_pos, y_pos), 4, POINT_COLOR)

func add_summary_statistics(data):
	if data.mood_values.size() == 0:
		return
	
	# Calculate stats
	var avg_mood = 0.0
	for value in data.mood_values:
		avg_mood += value
	avg_mood /= data.mood_values.size()
	
	var trend = "stable"
	if data.mood_values.size() >= 2:
		var first_half_avg = 0.0
		var second_half_avg = 0.0
		var mid_point = data.mood_values.size() / 2
		
		for i in range(mid_point):
			first_half_avg += data.mood_values[i]
		first_half_avg /= mid_point
		
		for i in range(mid_point, data.mood_values.size()):
			second_half_avg += data.mood_values[i]
		second_half_avg /= (data.mood_values.size() - mid_point)
		
		var diff = second_half_avg - first_half_avg
		if diff > 0.5:
			trend = "improving"
		elif diff < -0.5:
			trend = "declining"
	
	var stats_container = VBoxContainer.new()
	stats_container.custom_minimum_size = Vector2(320, 70)
	var avg_label = Label.new()
	avg_label.text = "Average Mood: " + str(avg_mood).substr(0, 4)
	stats_container.add_child(avg_label)
	
	var trend_label = Label.new()
	trend_label.text = "Trend: " + trend.capitalize()
	stats_container.add_child(trend_label)
	
	var entries_label = Label.new()
	entries_label.text = "Entries: " + str(data.mood_values.size())
	stats_container.add_child(entries_label)
	
	graph_container.add_child(stats_container)

func create_visual_graph_old(data):
	# Placeholder function - simplified graph
	var mood_values = data.mood_values
	var dates = data.dates
	
	var graph = VBoxContainer.new()
	graph.set("custom_minimum_size", Vector2(300, 200))
	
	# Create labels for some data points
	for i in range(min(mood_values.size(), 5)):
		var entry = HBoxContainer.new()
		
		var date_label = Label.new()
		date_label.text = dates[i] + ":"
		date_label.set("custom_minimum_size", Vector2(50, 0))
		entry.add_child(date_label)
		
		var mood_label = Label.new()
		mood_label.text = "Mood: " + str(mood_values[i])
		entry.add_child(mood_label)
		
		graph.add_child(entry)
	
	return graph
