extends Node2D
class_name ActivityList

@onready var activities_container = $CanvasLayer/ActivitiesContainer

# Recommended activities based on stored data
var recommended_activities = [
	{
		"name": "Take a walk outside",
		"category": "relax",
		"intensity": 0.4,
		"description": "A short walk can help clear your mind and improve mood."
	},
	{
		"name": "Call a friend",
		"category": "social",
		"intensity": 0.6,
		"description": "Social connection is important for mental wellbeing."
	},
	{
		"name": "Practice meditation",
		"category": "relax",
		"intensity": 0.3,
		"description": "Just 5 minutes of meditation can reduce stress."
	},
	{
		"name": "Read a book",
		"category": "relax",
		"intensity": 0.4,
		"description": "Reading can be a great escape and stress reliever."
	},
	{
		"name": "Exercise",
		"category": "work",
		"intensity": 0.8,
		"description": "Physical activity promotes better mental health."
	},
	{
		"name": "Try a new hobby",
		"category": "social",
		"intensity": 0.7,
		"description": "Learning something new creates positive emotions."
	},
	{
		"name": "Cook a healthy meal",
		"category": "work",
		"intensity": 0.5,
		"description": "Nutrition affects both physical and mental health."
	},
	{
		"name": "Listen to music",
		"category": "relax",
		"intensity": 0.3,
		"description": "Music can quickly change your emotional state."
	}
]

# Timer for updating active flow session display
var flow_timer = null
var flow_display_label = null
var add_button = null

func _ready() -> void:
	# Connect to the data_updated signal from DataStorage
	DataStorage.connect("data_updated", Callable(self, "_on_data_updated"))
	
	# Create flow timer
	flow_timer = Timer.new()
	flow_timer.wait_time = 1.0  # Update every second
	flow_timer.autostart = false
	flow_timer.one_shot = false
	flow_timer.connect("timeout", Callable(self, "_on_flow_timer_timeout"))
	add_child(flow_timer)
	
	# Load activities on startup
	load_activities()

func _process(delta) -> void:
	pass

func _on_data_updated():
	# Refresh the activities list when data is updated
	load_activities()

func _on_flow_timer_timeout():
	# Update the flow session display
	if flow_display_label != null:
		var active_session = DataStorage.get_active_flow_session()
		if active_session != null:
			var duration = Time.get_unix_time_from_system() - active_session["start_time"]
			var minutes = int(duration / 60)
			var seconds = int(duration) % 60
			flow_display_label.text = "Flow Time: %d:%02d" % [minutes, seconds]

func load_activities():
	# Clear existing activities list
	for child in activities_container.get_children():
		if child.name != "TitleLabel":  # Keep the title
			child.queue_free()
	
	# Add title if it doesn't exist
	if not activities_container.has_node("TitleLabel"):
		var title = Label.new()
		title.name = "TitleLabel"
		title.text = "Activities"
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		activities_container.add_child(title)
	
	# Check for active flow session first
	var active_session = DataStorage.get_active_flow_session()
	if active_session != null:
		show_active_flow_session(active_session)
		return
	
	# Display completed activities section
	add_completed_activities()
	
	# Add a separator
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 20)
	activities_container.add_child(separator)
	
	# Display recent flow sessions
	add_flow_sessions()
	
	# Add another separator
	var separator2 = HSeparator.new()
	separator2.custom_minimum_size = Vector2(0, 20)
	activities_container.add_child(separator2)
	
	# Display recommended activities based on mood data
	add_recommended_activities()
	
	# Add button to log a custom activity
	add_custom_activity_button()

func show_active_flow_session(active_session):
	# Create panel to display active flow session
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var vbox = VBoxContainer.new()
	panel.add_child(vbox)
	
	# Add active session label
	var active_label = Label.new()
	active_label.text = "Active Flow Session"
	active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	active_label.add_theme_color_override("font_color", Color(0.0, 0.6, 0.0))
	active_label.add_theme_font_size_override("font_size", 20)
	vbox.add_child(active_label)
	
	# Activity name and category
	var name_label = Label.new()
	name_label.text = active_session["activity_name"]
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(name_label)
	
	var category_label = Label.new()
	category_label.text = active_session["category"].capitalize()
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(category_label)
	
	# Add flow time display
	var time_label = Label.new()
	time_label.text = "Flow Time: 0:00"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(time_label)
	
	# Save reference to update this label
	flow_display_label = time_label
	flow_timer.start()
	
	# Add end flow button
	var end_button = Button.new()
	end_button.text = "End Flow Session"
	end_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	end_button.connect("pressed", Callable(self, "_on_end_flow_pressed"))
	vbox.add_child(end_button)
	
	activities_container.add_child(panel)

func add_flow_sessions():
	var flow_label = Label.new()
	flow_label.text = "Recent Flow Sessions"
	flow_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	flow_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	activities_container.add_child(flow_label)
	
	if DataStorage.user_data.has("flow_sessions") and DataStorage.user_data.flow_sessions.size() > 0:
		# Get most recent flow sessions (last 5)
		var sessions_to_show = min(5, DataStorage.user_data.flow_sessions.size())
		var start_index = max(0, DataStorage.user_data.flow_sessions.size() - sessions_to_show)
		
		for i in range(start_index, DataStorage.user_data.flow_sessions.size()):
			var session = DataStorage.user_data.flow_sessions[i]
			
			# Create panel for each flow session
			var panel = PanelContainer.new()
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var hbox = HBoxContainer.new()
			panel.add_child(hbox)
			
			# Session name and category
			var session_info = VBoxContainer.new()
			session_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var name_label = Label.new()
			name_label.text = session["activity_name"]
			session_info.add_child(name_label)
			
			var details_label = Label.new()
			details_label.text = session["category"].capitalize() + " - Flow: " + str(int(session["duration_minutes"])) + " min"
			details_label.add_theme_font_size_override("font_size", 12)
			details_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			session_info.add_child(details_label)
			
			hbox.add_child(session_info)
			
			# Convert timestamp to readable date
			var datetime = Time.get_datetime_dict_from_unix_time(session["end_time"])
			var date_str = "%02d/%02d %02d:%02d" % [datetime.month, datetime.day, datetime.hour, datetime.minute]
			
			var date_label = Label.new()
			date_label.text = date_str
			date_label.add_theme_font_size_override("font_size", 12)
			date_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			hbox.add_child(date_label)
			
			activities_container.add_child(panel)
	else:
		# No flow sessions yet
		var no_sessions = Label.new()
		no_sessions.text = "No flow sessions recorded yet"
		no_sessions.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_sessions.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		activities_container.add_child(no_sessions)

func add_completed_activities():
	# Display recently completed activities from storage
	var completed_label = Label.new()
	completed_label.text = "Recently Completed"
	completed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	completed_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	activities_container.add_child(completed_label)
	
	if DataStorage.user_data.has("activities") and DataStorage.user_data.activities.size() > 0:
		# Get most recent activities (last 5)
		var activities_to_show = min(5, DataStorage.user_data.activities.size())
		var start_index = max(0, DataStorage.user_data.activities.size() - activities_to_show)
		
		for i in range(start_index, DataStorage.user_data.activities.size()):
			var activity = DataStorage.user_data.activities[i]
			
			# Create panel for each activity
			var panel = PanelContainer.new()
			panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var hbox = HBoxContainer.new()
			panel.add_child(hbox)
			
			# Activity name and category
			var activity_info = VBoxContainer.new()
			activity_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var name_label = Label.new()
			name_label.text = activity.name
			activity_info.add_child(name_label)
			
			var category_label = Label.new()
			category_label.text = activity.category.capitalize()
			category_label.add_theme_font_size_override("font_size", 12)
			category_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			activity_info.add_child(category_label)
			
			hbox.add_child(activity_info)
			
			# Convert timestamp to readable date
			var datetime = Time.get_datetime_dict_from_unix_time(activity.timestamp)
			var date_str = "%02d/%02d %02d:%02d" % [datetime.month, datetime.day, datetime.hour, datetime.minute]
			
			var date_label = Label.new()
			date_label.text = date_str
			date_label.add_theme_font_size_override("font_size", 12)
			date_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			hbox.add_child(date_label)
			
			activities_container.add_child(panel)
	else:
		# No completed activities yet
		var no_activities = Label.new()
		no_activities.text = "No activities completed yet"
		no_activities.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		no_activities.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		activities_container.add_child(no_activities)

func add_recommended_activities():
	var recommended_label = Label.new()
	recommended_label.text = "Recommended For You"
	recommended_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	recommended_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.8))
	activities_container.add_child(recommended_label)
	
	# Get model input data to determine which activities to recommend
	var model_data = DataStorage.get_model_input_data()
	
	# Simple logic for recommendation (in a real app, this would use the ML model)
	var mood_score = model_data.get("mood_score", 3)
	var is_social = model_data.get("is_social", 0)
	var is_working = model_data.get("is_working", 0)
	var is_relaxing = model_data.get("is_relaxing", 0)
	
	# Filter activities based on user's recent behavior
	var filtered_activities = []
	
	# If mood is low, prioritize relaxation and social activities
	if mood_score < 3:
		for activity in recommended_activities:
			if (activity.category == "relax" and is_relaxing == 0) or \
			   (activity.category == "social" and is_social == 0):
				filtered_activities.append(activity)
	else:
		# For normal/high mood, suggest a balanced mix
		for activity in recommended_activities:
			if (activity.category == "work" and is_working == 0) or \
			   (filtered_activities.size() < 3):  # Ensure at least 3 recommendations
				filtered_activities.append(activity)
	
	# If we still don't have enough, add more from the original list
	while filtered_activities.size() < 3 and filtered_activities.size() < recommended_activities.size():
		for activity in recommended_activities:
			if not filtered_activities.has(activity):
				filtered_activities.append(activity)
				break
	
	# Display the recommended activities
	for activity in filtered_activities:
		if filtered_activities.size() >= 3:
			break  # Limit to 3 recommendations
			
		# Create a panel for each activity
		var panel = PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var vbox = VBoxContainer.new()
		panel.add_child(vbox)
		
		# Activity name
		var name_label = Label.new()
		name_label.text = activity.name
		vbox.add_child(name_label)
		
		# Activity description
		var desc_label = Label.new()
		desc_label.text = activity.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		vbox.add_child(desc_label)
		
		# Button container
		var button_container = HBoxContainer.new()
		button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_child(button_container)
		
		# Add "Start Flow" button
		var flow_button = Button.new()
		flow_button.text = "Start Flow"
		flow_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		flow_button.connect("pressed", Callable(self, "_on_start_flow_pressed").bind(activity))
		button_container.add_child(flow_button)
		
		# Add "Mark Complete" button
		var complete_button = Button.new()
		complete_button.text = "Mark Complete"
		complete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		complete_button.connect("pressed", Callable(self, "_on_complete_pressed").bind(activity))
		button_container.add_child(complete_button)
		
		activities_container.add_child(panel)

func add_custom_activity_button():
	# Add separator
	var separator = HSeparator.new()
	separator.custom_minimum_size = Vector2(0, 20)
	activities_container.add_child(separator)
	
	# Create a container for the add button to style it
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	activities_container.add_child(button_container)
	
	# Add button for adding new activity
	add_button = Button.new()
	add_button.text = "Add New Activity"
	add_button.icon = preload("res://Assets/Icons/plus.png") if ResourceLoader.exists("res://Assets/Icons/plus.png") else null
	add_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	add_button.connect("pressed", Callable(self, "_on_custom_activity_pressed"))
	button_container.add_child(add_button)

func _on_start_flow_pressed(activity):
	# Start flow session for this activity
	DataStorage.start_flow_session(activity.name, activity.category)
	
	# Refresh the activities list
	load_activities()

func _on_end_flow_pressed():
	# End the current flow session
	DataStorage.end_flow_session()
	
	# Stop the timer
	flow_timer.stop()
	flow_display_label = null
	
	# Refresh the activities list
	load_activities()

func _on_complete_pressed(activity):
	# Log the activity as completed
	DataStorage.add_activity(activity.name, activity.intensity, activity.category)
	
	# Refresh the activities list
	load_activities()

func _on_custom_activity_pressed():
	# Clear activities container except for title
	for child in activities_container.get_children():
		if child.name != "TitleLabel":  # Keep the title
			child.queue_free()
	
	# Create custom activity form container
	var form = VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	form.name = "ActivityForm"
	activities_container.add_child(form)
	
	# Form title
	var form_title = Label.new()
	form_title.text = "Add New Activity"
	form_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	form_title.add_theme_font_size_override("font_size", 20)
	form.add_child(form_title)
	
	# Name input
	var name_container = VBoxContainer.new()
	name_container.name = "name_container"
	form.add_child(name_container)
	
	var name_label = Label.new()
	name_label.text = "Activity Name:"
	name_container.add_child(name_label)
	
	var name_input = LineEdit.new()
	name_input.name = "name_input"
	name_input.placeholder_text = "Enter activity name"
	name_container.add_child(name_input)
	
	# Category selection
	var category_container = VBoxContainer.new()
	category_container.name = "category_container"
	form.add_child(category_container)
	
	var category_label = Label.new()
	category_label.text = "Category:"
	category_container.add_child(category_label)
	
	var category_options = OptionButton.new()
	category_options.name = "category_options"
	category_options.add_item("Social", 0)
	category_options.add_item("Work/Study", 1)
	category_options.add_item("Relaxation", 2)
	category_container.add_child(category_options)
	
	# Intensity slider
	var intensity_container = VBoxContainer.new()
	intensity_container.name = "intensity_container"
	form.add_child(intensity_container)
	
	var intensity_label = Label.new()
	intensity_label.text = "Intensity (1-5):"
	intensity_container.add_child(intensity_label)
	
	var slider_container = HBoxContainer.new()
	intensity_container.add_child(slider_container)
	
	var intensity_slider = HSlider.new()
	intensity_slider.name = "intensity_slider"
	intensity_slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	intensity_slider.min_value = 1
	intensity_slider.max_value = 5
	intensity_slider.step = 1
	intensity_slider.value = 3
	slider_container.add_child(intensity_slider)
	
	var intensity_value = Label.new()
	intensity_value.name = "intensity_value"
	intensity_value.text = "3"
	intensity_value.custom_minimum_size = Vector2(30, 0)
	intensity_slider.connect("value_changed", Callable(self, "_on_intensity_changed").bind(intensity_value))
	slider_container.add_child(intensity_value)
	
	var notes_container = VBoxContainer.new()
	notes_container.name = "notes_container"
	form.add_child(notes_container)
	
	var notes_label = Label.new()
	notes_label.text = "Notes (optional):"
	notes_container.add_child(notes_label)
	
	var notes_input = TextEdit.new()
	notes_input.name = "notes_input"
	notes_input.custom_minimum_size = Vector2(0, 60)
	notes_container.add_child(notes_input)
	
	var action_container = VBoxContainer.new()
	action_container.name = "action_container"
	form.add_child(action_container)
	
	var action_label = Label.new()
	action_label.text = "What would you like to do with this activity?"
	action_container.add_child(action_label)
	
	var action_options = HBoxContainer.new()
	action_options.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	action_container.add_child(action_options)
	
	var start_flow_button = Button.new()
	start_flow_button.name = "start_flow_button"
	start_flow_button.text = "Start Now"
	start_flow_button.tooltip_text = "Start tracking this activity now as a flow session"
	start_flow_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	start_flow_button.connect("pressed", Callable(self, "_on_custom_flow_start"))
	action_options.add_child(start_flow_button)
	
	var mark_complete_button = Button.new()
	mark_complete_button.name = "mark_complete_button"
	mark_complete_button.text = "Record as Done"
	mark_complete_button.tooltip_text = "Record this activity as already completed"
	mark_complete_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mark_complete_button.connect("pressed", Callable(self, "_on_custom_activity_submitted"))
	action_options.add_child(mark_complete_button)
	
	var cancel_container = HBoxContainer.new()
	cancel_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_container.alignment = BoxContainer.ALIGNMENT_CENTER
	form.add_child(cancel_container)
	
	var cancel_button = Button.new()
	cancel_button.name = "cancel_button"
	cancel_button.text = "Cancel"
	cancel_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	cancel_button.connect("pressed", Callable(self, "load_activities"))
	cancel_container.add_child(cancel_button)

func _on_intensity_changed(value, label):
	label.text = str(value)

func _on_custom_flow_start():
	var form = activities_container.get_node_or_null("ActivityForm")
	if form == null:
		print("Error: ActivityForm not found")
		return
		
	var name_input = form.get_node_or_null("name_container/name_input")
	var category_options = form.get_node_or_null("category_container/category_options")
	
	if name_input == null or category_options == null:
		print("Error: Required form components not found")
		return
	
	if name_input.text.strip_edges() == "":
		# Show error for empty name
		name_input.placeholder_text = "Required - please enter a name"
		return
	
	# Get activity data
	var activity_name = name_input.text
	var category_id = category_options.selected
	var category = "social"
	if category_id == 1:
		category = "work"
	elif category_id == 2:
		category = "relax"
	
	DataStorage.start_flow_session(activity_name, category)
	load_activities()

func _on_custom_activity_submitted():
	var form = activities_container.get_node_or_null("ActivityForm")
	if form == null:
		print("Error: ActivityForm not found")
		return
		
	var name_input = form.get_node_or_null("name_container/name_input")
	var category_options = form.get_node_or_null("category_container/category_options")
	
	if name_input == null or category_options == null:
		print("Error: Required form components not found")
		return
	
	var intensity_container = form.get_node_or_null("intensity_container") 
	if intensity_container == null:
		print("Error: Intensity container not found")
		return
		
	var slider_container = intensity_container.get_node_or_null("HBoxContainer")
	var intensity_slider = null
	if slider_container != null:
		intensity_slider = slider_container.get_node_or_null("intensity_slider")
	
	var intensity_value = 3.0
	if intensity_slider != null:
		intensity_value = intensity_slider.value
	else:
		print("Warning: Intensity slider not found, using default value")
	
	# Get notes component
	var notes_container = form.get_node_or_null("notes_container")
	var notes_text = ""
	if notes_container != null:
		var notes_input = notes_container.get_node_or_null("notes_input")
		if notes_input != null:
			notes_text = notes_input.text
	
	if name_input.text.strip_edges() == "":
		# Show error for empty name
		name_input.placeholder_text = "Required - please enter a name"
		return
	
	# Get activity data
	var activity_name = name_input.text
	var category_id = category_options.selected
	var category = "social"
	if category_id == 1:
		category = "work"
	elif category_id == 2:
		category = "relax"
	
	# Normalize intensity to 0-1 range
	var normalized_intensity = float(intensity_value) / 5.0
	
	DataStorage.add_activity(activity_name, normalized_intensity, category, notes_text)
	load_activities() 
