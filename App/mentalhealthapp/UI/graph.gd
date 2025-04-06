extends Node2D
class_name Graph

@onready var canvas_layer = $CanvasLayer
@onready var graph_container = $CanvasLayer/GraphContainer

# Colors for the graph
const BACKGROUND_COLOR = Color("#474747")
const LINE_COLOR = Color("#4285F4")
const POINT_COLOR = Color("#DB4437")
const GRID_COLOR = Color("#9AA0A6")
const PREDICTION_COLOR = Color("#0F9D58")  # Green for prediction

# Mood predictor
var mood_predictor = null
var prediction_value = null
var show_prediction = false

func _ready() -> void:
	DataStorage.connect("data_updated", Callable(self, "_on_data_updated"))
	
	# Initialize the mood predictor
	mood_predictor = MoodPredictor.new()
	add_child(mood_predictor)
	mood_predictor.connect("prediction_completed", Callable(self, "_on_prediction_completed"))
	
	create_graph()
	add_prediction_button()

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
			
			# Get the correct weekday (0-6, Sunday-Saturday)
			# Use the correct field from datetime dictionary
			var weekday = datetime.weekday if datetime.has("weekday") else 0
			
			# If weekday is not available, calculate it using Zeller's congruence
			if !datetime.has("weekday"):
				var day = datetime.day
				var month = datetime.month
				var year = datetime.year
				
				# Adjust month and year for Zeller's formula
				if month < 3:
					month += 12
					year -= 1
				
				var h = (day + int((13 * (month + 1)) / 5) + year + int(year / 4) - int(year / 100) + int(year / 400)) % 7
				# Convert h (0=Saturday, 1=Sunday, ...) to our format (0=Sunday, ..., 6=Saturday)
				weekday = (h + 1) % 7
			
			var day_name = day_names[weekday]
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
	
	# Include prediction in min/max calculation if available
	if show_prediction and prediction_value != null:
		min_value = min(min_value, prediction_value)
		max_value = max(max_value, prediction_value)

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
	
	# Draw prediction point and line if available
	if show_prediction and prediction_value != null:
		var last_x = padding.x + (values.size() - 1) * x_scale
		var last_y = size.y - padding.y - (values[values.size() - 1] - min_value) * y_scale
		var pred_x = padding.x + values.size() * x_scale
		var pred_y = size.y - padding.y - (prediction_value - min_value) * y_scale
		
		# Draw dashed line to prediction (future)
		control.draw_dashed_line(Vector2(last_x, last_y), Vector2(pred_x, pred_y), PREDICTION_COLOR, 2.0)
		
		# Draw prediction point
		control.draw_circle(Vector2(pred_x, pred_y), 5, PREDICTION_COLOR)
		
		# Add "Predicted" label
		var font = control.get_theme_default_font()
		var font_size = control.get_theme_default_font_size()
		control.draw_string(font, Vector2(pred_x - 15, pred_y - 12), "Predicted", HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

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
	
	# Show prediction if available
	if show_prediction and prediction_value != null:
		var pred_label = Label.new()
		pred_label.text = "Predicted Mood: " + str(prediction_value).substr(0, 4)
		pred_label.add_theme_color_override("font_color", PREDICTION_COLOR)
		stats_container.add_child(pred_label)
	
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

func add_prediction_button():
	var predict_button = Button.new()
	predict_button.text = "Predict Future Mood"
	predict_button.connect("pressed", Callable(self, "_on_predict_button_pressed"))
	graph_container.add_child(predict_button)

func _on_predict_button_pressed():
	# Get user's data as input features
	# This will depend on what features your model expects
	var features = get_prediction_features()
	
	# Call the prediction function
	print("Requesting mood prediction with features:", features)
	mood_predictor.predict_mood(features)

func _on_prediction_completed(result):
	print("Prediction completed:", result)
	
	# Remove any previous error messages
	for child in graph_container.get_children():
		if child is Label and child.text.begins_with("Prediction failed:"):
			child.queue_free()
	
	if result is Dictionary:
		if result.has("prediction") and result.has("status") and result.status == "success":
			prediction_value = result.prediction
			show_prediction = true
			# Update graph to show prediction
			create_graph()
		elif result.has("error"):
			# Show error message
			var error_message = result.get("message", str(result.error))
			var error_label = Label.new()
			error_label.text = "Prediction failed: " + error_message
			error_label.add_theme_color_override("font_color", Color.RED)
			graph_container.add_child(error_label)
	elif result is String:
		# Try to parse the result as JSON if it's a string
		var json = JSON.new()
		var error = json.parse(result)
		
		if error == OK:
			var parsed_result = json.data
			if typeof(parsed_result) == TYPE_DICTIONARY:
				if parsed_result.has("prediction") and parsed_result.has("status") and parsed_result.status == "success":
					prediction_value = parsed_result.prediction
					show_prediction = true
					# Update graph to show prediction
					create_graph()
				elif parsed_result.has("error"):
					# Show error message
					var error_label = Label.new()
					error_label.text = "Prediction failed: " + str(parsed_result.error)
					error_label.add_theme_color_override("font_color", Color.RED)
					graph_container.add_child(error_label)
		else:
			# Show that we couldn't parse the result
			var error_label = Label.new()
			error_label.text = "Prediction failed: Could not parse result - " + result
			error_label.add_theme_color_override("font_color", Color.RED)
			graph_container.add_child(error_label)
	else:
		# Show a generic error for any other type
		var error_label = Label.new()
		error_label.text = "Prediction failed: Unexpected result type"
		error_label.add_theme_color_override("font_color", Color.RED)
		graph_container.add_child(error_label)

func get_prediction_features():
	# Extract features from user data based on wellbeing_train.py
	# Required features: DAILY_STRESS, FLOW, TODO_COMPLETED, SLEEP_HOURS, GENDER, AGE
	var features = {}
	
	# DAILY_STRESS - Scale of 1-5
	if DataStorage.user_data.has("stress_level"):
		features["DAILY_STRESS"] = DataStorage.user_data.stress_level
	else:
		features["DAILY_STRESS"] = 3.0  # Default value on scale of 1-5
	
	# FLOW - Engagement/focus (1-5)
	if DataStorage.user_data.has("flow") or DataStorage.user_data.has("focus"):
		features["FLOW"] = DataStorage.user_data.get("flow", DataStorage.user_data.get("focus", 3.0))
	else:
		features["FLOW"] = 3.0  # Default value
	
	# TODO_COMPLETED - Percentage or count of completed tasks
	if DataStorage.user_data.has("todo_completed"):
		features["TODO_COMPLETED"] = DataStorage.user_data.todo_completed
	elif DataStorage.user_data.has("todo_list") and typeof(DataStorage.user_data.todo_list) == TYPE_ARRAY:
		# Calculate percentage of completed todos
		var total_todos = DataStorage.user_data.todo_list.size()
		var completed_todos = 0
		for todo in DataStorage.user_data.todo_list:
			if typeof(todo) == TYPE_DICTIONARY and todo.has("completed") and todo.completed:
				completed_todos += 1
		
		if total_todos > 0:
			features["TODO_COMPLETED"] = float(completed_todos) / total_todos * 100.0
		else:
			features["TODO_COMPLETED"] = 50.0  # Default 50%
	else:
		features["TODO_COMPLETED"] = 50.0  # Default 50%
	
	# SLEEP_HOURS
	if DataStorage.user_data.has("sleep_data"):
		# Check the type and access appropriately
		if typeof(DataStorage.user_data.sleep_data) == TYPE_ARRAY:
			# If it's an array, use the latest entry
			if DataStorage.user_data.sleep_data.size() > 0:
				var latest_sleep = DataStorage.user_data.sleep_data.back()
				if typeof(latest_sleep) == TYPE_DICTIONARY and latest_sleep.has("hours"):
					features["SLEEP_HOURS"] = latest_sleep.hours
				elif typeof(latest_sleep) == TYPE_DICTIONARY and latest_sleep.has("hours_slept"):
					features["SLEEP_HOURS"] = latest_sleep.hours_slept
				else:
					features["SLEEP_HOURS"] = 7.0  # Default value
			else:
				features["SLEEP_HOURS"] = 7.0  # Default value
		elif typeof(DataStorage.user_data.sleep_data) == TYPE_DICTIONARY:
			# If it's a dictionary with hours property
			if DataStorage.user_data.sleep_data.has("hours"):
				features["SLEEP_HOURS"] = DataStorage.user_data.sleep_data.hours
			elif DataStorage.user_data.sleep_data.has("hours_slept"):
				features["SLEEP_HOURS"] = DataStorage.user_data.sleep_data.hours_slept
			else:
				features["SLEEP_HOURS"] = 7.0  # Default value
		else:
			features["SLEEP_HOURS"] = 7.0  # Default value
	else:
		features["SLEEP_HOURS"] = 7.0  # Default value
	
	# GENDER - Use user profile data
	if DataStorage.user_data.has("user_profile") and DataStorage.user_data.user_profile.has("gender"):
		features["GENDER"] = DataStorage.user_data.user_profile.gender
	else:
		features["GENDER"] = "Other"  # Default value
	
	# AGE - Use user profile data
	if DataStorage.user_data.has("user_profile") and DataStorage.user_data.user_profile.has("age"):
		features["AGE"] = float(DataStorage.user_data.user_profile.age)
	else:
		features["AGE"] = 30.0  # Default value
	
	print("Extracted features based on wellbeing model: ", features)
	return features
