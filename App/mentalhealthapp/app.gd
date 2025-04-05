extends Node
class_name App

# Page references
@onready var page_select_button = $Control/PageSelect/Button
@onready var central_panel = $Control/CentralPanel

# Current page index (0: graph, 1: survey, 2: activity list)
var current_page = 0
var total_pages = 3
var is_transitioning = false
var screen_width = 360 # Match the width we set in app.tscn

# Touch input tracking
var touch_start_position = Vector2.ZERO
var is_dragging = false
var min_swipe_distance = 50

# Scene resources
var graph_scene_res = preload("res://UI/graph.tscn")
var survey_scene_res = preload("res://UI/survey.tscn")
var activity_list_scene_res = preload("res://UI/activity_list.tscn")

# Current and next scene instances
var current_scene_instance
var next_scene_instance

func _ready():
	# Add graph as default starting page
	current_scene_instance = graph_scene_res.instantiate()
	central_panel.add_child(current_scene_instance)
	update_page_button_text()
	
	# Enable touch input processing
	Input.set_use_accumulated_input(false)

func _process(delta):
	pass

func _input(event):
	if is_transitioning:
		return
		
	if event is InputEventScreenTouch:
		if event.pressed:
			# Touch began
			touch_start_position = event.position
			is_dragging = true
		elif is_dragging:
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
	
	elif event is InputEventScreenDrag and is_dragging:
		# Update dragging for potential swipe
		pass

func _on_page_select_pressed():
	if is_transitioning:
		return
		
	# Calculate next page index
	var next_page = (current_page + 1) % total_pages
	transition_to_page(next_page)

func transition_to_page(next_page, from_right = false):
	is_transitioning = true
	
	# Create the next scene instance
	next_scene_instance = get_scene_for_page(next_page)
	central_panel.add_child(next_scene_instance)
	
	# Position the next scene based on the direction
	if from_right:
		# Coming from the right (previous page)
		next_scene_instance.position.x = -screen_width
	else:
		# Coming from the left (next page)
		next_scene_instance.position.x = screen_width
	
	# Create two tweens - one for current scene, one for next scene
	var tween_current = create_tween()
	var tween_next = create_tween()
	
	# Animate based on direction
	if from_right:
		# Current moves right, next comes from left
		tween_current.tween_property(current_scene_instance, "position:x", screen_width, 0.5)
		tween_next.tween_property(next_scene_instance, "position:x", 0, 0.5)
	else:
		# Current moves left, next comes from right
		tween_current.tween_property(current_scene_instance, "position:x", -screen_width, 0.5)
		tween_next.tween_property(next_scene_instance, "position:x", 0, 0.5)
	
	# Set easing for both tweens
	tween_current.set_ease(Tween.EASE_IN_OUT)
	tween_current.set_trans(Tween.TRANS_QUAD)
	tween_next.set_ease(Tween.EASE_IN_OUT)
	tween_next.set_trans(Tween.TRANS_QUAD)
	
	# Connect the tween completion signal
	tween_next.finished.connect(func(): _on_transition_finished(next_page))

func _on_transition_finished(next_page):
	# Remove the old scene
	current_scene_instance.queue_free()
	
	# Update references
	current_scene_instance = next_scene_instance
	next_scene_instance = null
	current_page = next_page
	
	# Update button text
	update_page_button_text()
	
	# Reset transition flag
	is_transitioning = false

func get_scene_for_page(page_index):
	match page_index:
		0: # Graph
			return graph_scene_res.instantiate()
		1: # Survey
			return survey_scene_res.instantiate()
		2: # Activity List
			return activity_list_scene_res.instantiate()
	return null

func update_page_button_text():
	match current_page:
		0: # Graph
			page_select_button.text = "Graph > Survey"
		1: # Survey
			page_select_button.text = "Survey > Activities"
		2: # Activity List
			page_select_button.text = "Activities > Graph"
