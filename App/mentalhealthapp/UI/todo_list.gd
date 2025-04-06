extends Node2D
class_name TodoList

@onready var todo_container = $CanvasLayer/TodoContainer

func _ready() -> void:
	DataStorage.connect("data_updated", Callable(self, "_on_data_updated"))
	load_todos()

func _on_data_updated():
	load_todos()

func load_todos():
	for child in todo_container.get_children():
		if child.name != "TitleLabel" and child.name != "AddTodoButton":
			child.queue_free()
	
	if DataStorage.user_data.has("todos") and DataStorage.user_data.todos.size() > 0:
		var active_label = Label.new()
		active_label.text = "Active Tasks"
		active_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		active_label.add_theme_color_override("font_color", Color(0.2, 0.2, 0.8))
		todo_container.add_child(active_label)
		
		var active_count = 0
		for i in range(DataStorage.user_data.todos.size()):
			var todo = DataStorage.user_data.todos[i]
			if not todo.completed:
				add_todo_item(todo, i)
				active_count += 1
		
		if active_count == 0:
			var no_active = Label.new()
			no_active.text = "No active tasks"
			no_active.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			no_active.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			todo_container.add_child(no_active)
		
		var separator = HSeparator.new()
		separator.custom_minimum_size = Vector2(0, 20)
		todo_container.add_child(separator)
		
		var completed_label = Label.new()
		completed_label.text = "Completed Tasks"
		completed_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		completed_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
		todo_container.add_child(completed_label)
		
		var completed_count = 0
		for i in range(DataStorage.user_data.todos.size()):
			var todo = DataStorage.user_data.todos[i]
			if todo.completed:
				add_completed_todo_item(todo, i)
				completed_count += 1
				
				# Only show max of 5 completed todos
				if completed_count >= 5:
					break
		
		if completed_count == 0:
			var no_completed = Label.new()
			no_completed.text = "No completed tasks"
			no_completed.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			no_completed.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			todo_container.add_child(no_completed)
	else:
		var no_todos = Label.new()
		no_todos.text = "No tasks yet. Add your first task!"
		no_todos.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		todo_container.add_child(no_todos)
	
	# Make sure add button is at the end
	var add_button = todo_container.get_node("AddTodoButton")
	if add_button:
		todo_container.move_child(add_button, todo_container.get_child_count() - 1)

func add_todo_item(todo, index):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var checkbox = CheckBox.new()
	checkbox.button_pressed = false
	checkbox.connect("toggled", Callable(self, "_on_todo_toggled").bind(index))
	checkbox.add_theme_color_override("font_color", Color(0, 0, 1))
	checkbox.add_theme_color_override("font_color_pressed", Color(0, 0, 1))
	checkbox.add_theme_color_override("icon_normal_color", Color(0, 0, 1))
	checkbox.add_theme_color_override("icon_pressed_color", Color(0, 0, 1))
	hbox.add_child(checkbox)
	
	var todo_info = VBoxContainer.new()
	todo_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = todo.title
	todo_info.add_child(title_label)
	
	if todo.description and todo.description.strip_edges() != "":
		var desc_label = Label.new()
		desc_label.text = todo.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		todo_info.add_child(desc_label)
	
	hbox.add_child(todo_info)
	
	# Due date if any
	if todo.due_date > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(todo.due_date)
		var date_str = "%02d/%02d %02d:%02d" % [datetime.month, datetime.day, datetime.hour, datetime.minute]
		
		var date_label = Label.new()
		date_label.text = "Due: " + date_str
		date_label.add_theme_font_size_override("font_size", 12)
		date_label.add_theme_color_override("font_color", Color(0.8, 0.2, 0.2))
		hbox.add_child(date_label)
	
	todo_container.add_child(panel)

func add_completed_todo_item(todo, index):
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var hbox = HBoxContainer.new()
	panel.add_child(hbox)
	
	var todo_info = VBoxContainer.new()
	todo_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var title_label = Label.new()
	title_label.text = todo.title
	title_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	todo_info.add_child(title_label)
	
	hbox.add_child(todo_info)
	
	var datetime = Time.get_datetime_dict_from_unix_time(todo.completion_timestamp)
	var date_str = "%02d/%02d %02d:%02d" % [datetime.month, datetime.day, datetime.hour, datetime.minute]
	
	var date_label = Label.new()
	date_label.text = "Completed: " + date_str
	date_label.add_theme_font_size_override("font_size", 12)
	date_label.add_theme_color_override("font_color", Color(0.2, 0.6, 0.2))
	hbox.add_child(date_label)
	
	todo_container.add_child(panel)

func _on_todo_toggled(is_button_pressed, todo_index):
	if is_button_pressed:
		DataStorage.complete_todo(todo_index)

func _on_add_todo_pressed():
	show_add_todo_form()

func show_add_todo_form():
	for child in todo_container.get_children():
		if child.name != "TitleLabel" and child.name != "AddTodoButton":
			child.queue_free()
	var form = VBoxContainer.new()
	form.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_label = Label.new()
	title_label.text = "Task Title:"
	form.add_child(title_label)
	
	var title_input = LineEdit.new()
	title_input.name = "title_input"
	title_input.placeholder_text = "Enter task title"
	form.add_child(title_input)
	
	var desc_label = Label.new()
	desc_label.text = "Description (optional):"
	form.add_child(desc_label)
	
	var desc_input = TextEdit.new()
	desc_input.name = "desc_input"
	desc_input.custom_minimum_size = Vector2(0, 60)
	form.add_child(desc_input)

	var due_date_hbox = HBoxContainer.new()
	var due_date_check = CheckBox.new()
	due_date_check.name = "due_date_check"
	due_date_check.text = "Set Due Date"
	due_date_hbox.add_child(due_date_check)
	form.add_child(due_date_hbox)
	
	var due_date_container = VBoxContainer.new()
	due_date_container.name = "due_date_container"
	due_date_container.visible = false # Hidden by default
	
	var date_label = Label.new()
	date_label.text = "Due Date:"
	due_date_container.add_child(date_label)
	
	# Some calendar date picker integration would go here in a real app
	# For simplicity, use a shitty dropdown for day and time
	
	var date_hbox = HBoxContainer.new()
	
	var day_options = OptionButton.new()
	day_options.name = "day_options"
	
	var current_time = Time.get_unix_time_from_system()
	for i in range(7):
		var day_timestamp = current_time + (i * 86400)  # 86400 seconds in a day
		var day_datetime = Time.get_datetime_dict_from_unix_time(day_timestamp)
		var day_str = "%s %d/%d" % [
			["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][day_datetime.weekday],
			day_datetime.month,
			day_datetime.day
		]
		day_options.add_item(day_str, i)
	
	date_hbox.add_child(day_options)
	
	var time_options = OptionButton.new()
	time_options.name = "time_options"
	
	# Propogate times
	for hour in range(8, 23, 2):  # 8 AM to 10 PM in 2-hour increments
		var am_pm = "AM" if hour < 12 else "PM"
		var display_hour = hour if hour <= 12 else hour - 12
		if display_hour == 0:
			display_hour = 12
		time_options.add_item("%d:00 %s" % [display_hour, am_pm], hour - 8)
	
	date_hbox.add_child(time_options)
	
	due_date_container.add_child(date_hbox)
	form.add_child(due_date_container)
	due_date_check.connect("toggled", Callable(self, "_on_due_date_toggled").bind(due_date_container))
	
	var button_container = HBoxContainer.new()
	button_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var cancel_button = Button.new()
	cancel_button.text = "Cancel"
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.connect("pressed", Callable(self, "load_todos"))
	button_container.add_child(cancel_button)
	
	var save_button = Button.new()
	save_button.text = "Save Task"
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.connect("pressed", Callable(self, "_on_save_todo").bind(form))
	button_container.add_child(save_button)
	
	form.add_child(button_container)
	
	todo_container.add_child(form)

func _on_due_date_toggled(is_button_pressed, due_date_container):
	due_date_container.visible = is_button_pressed

func _on_save_todo(form):
	var title_input = form.get_node("title_input")
	var desc_input = form.get_node("desc_input")
	var due_date_check = form.get_node("due_date_check")
	
	if title_input.text.strip_edges() == "":
		# Show error text for empty title
		title_input.placeholder_text = "Required - please enter a title"
		return
	
	var title = title_input.text
	var description = desc_input.text
	var due_date = 0
	
	if due_date_check != null and due_date_check.button_pressed:
		var due_date_container = form.get_node("due_date_container")
		var day_options = due_date_container.get_node("day_options")
		var time_options = due_date_container.get_node("time_options")
		
		# Calculate due date from selections
		var current_time = Time.get_unix_time_from_system()
		var day_offset = day_options.selected * 86400  # Days in seconds
		var hour_offset = (time_options.selected * 2 + 8) * 3600
		
		# Start with current day at midnight
		var datetime = Time.get_datetime_dict_from_system()
		var midnight = current_time - (datetime.hour * 3600 + datetime.minute * 60 + datetime.second)
		
		due_date = midnight + day_offset + hour_offset
	
	DataStorage.add_todo(title, description, due_date)
	load_todos() 
