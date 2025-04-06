extends Node
class_name App

# Page references
@onready var page_select_button = $Control/PageSelect/Button
@onready var central_panel = $Control/CentralPanel

# Current page index (0: graph, 1: survey, 2: activity list, 3: todo list, 4: profile)
var current_page = 0
var total_pages = 5
var is_transitioning = false
var screen_width = 360 # Match the width we set in app.tscn

# Touch input tracking
var touch_start_position = Vector2.ZERO
var is_dragging = false
var min_swipe_distance = 50
var drag_threshold = 10 # Minimum distance to consider it a drag
var drag_scene_position = Vector2.ZERO # 
var mouse_button_pressed = false 
var is_ui_interaction = false

# Scene resources
var graph_scene_res = preload("res://UI/graph.tscn")
var survey_scene_res = preload("res://UI/survey.tscn")
var activity_list_scene_res = preload("res://UI/activity_list.tscn")
var todo_list_scene_res = preload("res://UI/todo_list.tscn")  
var user_profile_scene_res = preload("res://UI/user_profile.tscn")

# Current and next scene instances
var current_scene_instance
var next_scene_instance

func _ready():
	# Check if user profile is set, if not, start with profile page
	if DataStorage.user_data.has("user_profile") and DataStorage.user_data["user_profile"]["gender"] != "" and DataStorage.user_data["user_profile"]["age"] > 0:
		# Add graph as default starting page
		current_page = 0
		current_scene_instance = graph_scene_res.instantiate()
	else:
		# Start with profile setup
		current_page = 4
		current_scene_instance = user_profile_scene_res.instantiate()
	
	central_panel.add_child(current_scene_instance)
	update_page_button_text()
	
	# Enable touch input processing
	Input.set_use_accumulated_input(false)

func _process(delta):
	pass


func is_interacting_with_ui(event_position):
	var controls = _get_all_controls(get_tree().root)
	
	for control in controls:
		if control is Slider or control is Button or control is SpinBox or control is CheckBox or control is LineEdit or control is TextEdit or control is OptionButton:
			# Check if the control is visible and contains the event position
			if control.visible and control.get_global_rect().has_point(event_position):
				return true
	
	return false

# Helper function to recursively get all controls in the scene
func _get_all_controls(node):
	var controls = []
	
	if node is Control:
		controls.append(node)
	
	for child in node.get_children():
		controls.append_array(_get_all_controls(child))
	
	return controls

func _input(event):
	if is_transitioning:
		return
	
	# Handle touch input
	if event is InputEventScreenTouch:
		if event.pressed:
			# Check if touching a UI control
			is_ui_interaction = is_interacting_with_ui(event.position)
			if is_ui_interaction:
				return
				
			# Touch began
			touch_start_position = event.position
			is_dragging = true
			drag_scene_position = Vector2.ZERO
		elif is_dragging and not is_ui_interaction:
			# Touch ended, check for swipe
			is_dragging = false
			var swipe_distance = event.position.x - touch_start_position.x
			
			if abs(swipe_distance) > min_swipe_distance:
				if swipe_distance < 0:
					# Swipe left -> next page
					var next_page = (current_page + 1) % total_pages
					transition_to_page(next_page)
				else:
					# Swipe right -> previous page
					var prev_page = (current_page - 1 + total_pages) % total_pages
					transition_to_page(prev_page, true) # true means coming from right
			else:
				# Not enough distance for swipe, cancel the drag
				cancel_drag()
	
	# Handle mouse input (to emulate touch on PC)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				is_ui_interaction = is_interacting_with_ui(event.position)
				if is_ui_interaction:
					return
				
				# Mouse button down = touch start
				touch_start_position = event.position
				is_dragging = true
				mouse_button_pressed = true
				drag_scene_position = Vector2.ZERO # Reset drag position
			elif is_dragging and mouse_button_pressed and not is_ui_interaction:
				# Mouse button up = touch end
				is_dragging = false
				mouse_button_pressed = false
				var swipe_distance = event.position.x - touch_start_position.x
				
				if abs(swipe_distance) > min_swipe_distance:
					if swipe_distance < 0:
						# Swipe left -> next page
						var next_page = (current_page + 1) % total_pages
						transition_to_page(next_page)
					else:
						# Swipe right -> previous page
						var prev_page = (current_page - 1 + total_pages) % total_pages
						transition_to_page(prev_page, true) # true means coming from right
				else:
					# Not enough distance for swipe, cancel the drag
					cancel_drag()
	
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and not is_ui_interaction:
		if (event is InputEventScreenDrag) or (event is InputEventMouseMotion and mouse_button_pressed and is_dragging):
			var drag_distance = event.position.x - touch_start_position.x
			if abs(drag_distance) > drag_threshold:
				if drag_distance < 0:
					# Dragging left, show next page
					if next_scene_instance == null:
						var next_page = (current_page + 1) % total_pages
						next_scene_instance = get_scene_for_page(next_page)
						central_panel.add_child(next_scene_instance)
						var canvas_layer = next_scene_instance.get_node("CanvasLayer")
						canvas_layer.offset = Vector2(screen_width, 0) # Right is screen_width
				else:
					# Dragging right, show previous page
					if next_scene_instance == null:
						var prev_page = (current_page - 1 + total_pages) % total_pages
						next_scene_instance = get_scene_for_page(prev_page)
						central_panel.add_child(next_scene_instance)
						var canvas_layer = next_scene_instance.get_node("CanvasLayer")
						canvas_layer.offset = Vector2(-screen_width, 0) # Left is -screen_width
				
				# Move both current and next scenes based on drag distance
				var current_canvas = current_scene_instance.get_node("CanvasLayer")
				current_canvas.offset = Vector2(drag_distance, 0)
				if next_scene_instance != null:
					var next_canvas = next_scene_instance.get_node("CanvasLayer")
					if drag_distance < 0:
						# Coming from right
						next_canvas.offset = Vector2(screen_width + drag_distance, 0)
					else:
						# Coming from left
						next_canvas.offset = Vector2(-screen_width + drag_distance, 0)

func _on_page_select_pressed():
	if is_transitioning:
		return
	var next_page = (current_page + 1) % total_pages
	transition_to_page(next_page)

func transition_to_page(next_page, from_right = false):
	is_transitioning = true
	
	if next_scene_instance != null:
		next_scene_instance.queue_free()
	
	next_scene_instance = get_scene_for_page(next_page)
	central_panel.add_child(next_scene_instance)
	
	var current_canvas = current_scene_instance.get_node("CanvasLayer")
	var next_canvas = next_scene_instance.get_node("CanvasLayer")
	
	if from_right:
		# Coming from the right, previous page
		next_canvas.offset = Vector2(-screen_width, 0)
	else:
		# Coming from the left, next page
		next_canvas.offset = Vector2(screen_width, 0)
	
	var tween_current = create_tween()
	var tween_next = create_tween()
	
	var transition_duration = 0.35
	
	if from_right:
		# Current moves right, next comes from left
		tween_current.tween_property(current_canvas, "offset:x", screen_width, transition_duration)
		tween_next.tween_property(next_canvas, "offset:x", 0, transition_duration)
	else:
		# Current moves left, next comes from right
		tween_current.tween_property(current_canvas, "offset:x", -screen_width, transition_duration)
		tween_next.tween_property(next_canvas, "offset:x", 0, transition_duration)
	
	tween_current.set_ease(Tween.EASE_OUT)
	tween_current.set_trans(Tween.TRANS_QUAD)
	tween_next.set_ease(Tween.EASE_OUT)
	tween_next.set_trans(Tween.TRANS_QUAD)
	tween_next.finished.connect(func(): _on_transition_finished(next_page))

func _on_transition_finished(next_page):
	current_scene_instance.queue_free()
	current_scene_instance = next_scene_instance
	next_scene_instance = null
	current_page = next_page
	update_page_button_text()
	is_transitioning = false
	is_ui_interaction = false

func cancel_drag():
	if next_scene_instance != null:
		next_scene_instance.queue_free()
		next_scene_instance = null
		var current_canvas = current_scene_instance.get_node("CanvasLayer")
		
		# Animation
		var tween = create_tween()
		tween.tween_property(current_canvas, "offset:x", 0, 0.2)
		tween.set_ease(Tween.EASE_OUT)
		tween.set_trans(Tween.TRANS_BACK) # Use TRANS_BACK for a slight spring effect
	else:
		# Just reset the current scene position if no next scene
		var current_canvas = current_scene_instance.get_node("CanvasLayer")
		current_canvas.offset.x = 0
	
	is_dragging = false
	is_ui_interaction = false

func get_scene_for_page(page_index):
	match page_index:
		0: # Graph
			return graph_scene_res.instantiate()
		1: # Survey
			return survey_scene_res.instantiate()
		2: # Activity List
			return activity_list_scene_res.instantiate()
		3: # Todo List
			return todo_list_scene_res.instantiate()
		4: # User Profile
			return user_profile_scene_res.instantiate()
	return null

func update_page_button_text():
	match current_page:
		0: # Graph
			page_select_button.text = "Graph > Survey"
		1: # Survey
			page_select_button.text = "Survey > Activities"
		2: # Activity List
			page_select_button.text = "Activities > Tasks"
		3: # Todo List
			page_select_button.text = "Tasks > Profile"
		4: # User Profile
			page_select_button.text = "Profile > Graph"
