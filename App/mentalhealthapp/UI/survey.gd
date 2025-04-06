extends Node2D
class_name Survey

@onready var questions_container = $CanvasLayer/SurveyContainer/QuestionsContainer
@onready var submit_button = $CanvasLayer/SurveyContainer/SubmitButton

var questions = [
	{
		"id": "daily_stress",
		"text": "What is your stress level today?",
		"type": "slider",
		"min": 1,
		"max": 5,
		"default": 3
	},
	{
		"id": "mood_score",
		"text": "How would you rate your mood today?",
		"type": "slider",
		"min": 1,
		"max": 5,
		"default": 3
	},
	{
		"id": "sleep_quality",
		"text": "How well did you sleep last night?",
		"type": "slider",
		"min": 1,
		"max": 5,
		"default": 3
	},
	{
		"id": "sleep_duration",
		"text": "How many hours did you sleep?",
		"type": "spinbox",
		"min": 0,
		"max": 12,
		"default": 7,
		"step": 0.5
	},
	{
		"id": "activity_social",
		"text": "Did you engage in social activities today?",
		"type": "checkbox",
		"default": false
	},
	{
		"id": "activity_work",
		"text": "Did you work or study today?",
		"type": "checkbox",
		"default": false
	},
	{
		"id": "activity_relax",
		"text": "Did you take time to relax today?",
		"type": "checkbox",
		"default": false
	}
]

var responses = {}

func _ready() -> void:
	create_question_ui()
	submit_button.connect("pressed", Callable(self, "_on_submit_pressed"))

func _process(delta) -> void:
	pass

func create_question_ui():
	for child in questions_container.get_children():
		child.queue_free()
	
	for question in questions:
		var question_container = VBoxContainer.new()
		question_container.name = question.id
		
		var label = Label.new()
		label.text = question.text
		question_container.add_child(label)
		
		match question.type:
			"slider":
				var slider = HSlider.new()
				slider.name = "input"
				slider.min_value = question.min
				slider.max_value = question.max
				slider.step = 1
				slider.value = question.default
				var value_label = Label.new()
				value_label.name = "value"
				value_label.text = str(question.default)
				slider.connect("value_changed", Callable(self, "_on_slider_changed").bind(value_label))
				question_container.add_child(slider)
				question_container.add_child(value_label)
				responses[question.id] = question.default
				
			"spinbox":
				var spinbox = SpinBox.new()
				spinbox.name = "input"
				spinbox.min_value = question.min
				spinbox.max_value = question.max
				spinbox.step = question.step
				spinbox.value = question.default
				spinbox.connect("value_changed", Callable(self, "_on_spinbox_changed").bind(question.id))
				question_container.add_child(spinbox)
				responses[question.id] = question.default
				
			"checkbox":
				var checkbox = CheckBox.new()
				checkbox.name = "input"
				checkbox.text = "Yes"
				checkbox.button_pressed = question.default
				checkbox.connect("toggled", Callable(self, "_on_checkbox_toggled").bind(question.id))
				question_container.add_child(checkbox)
				responses[question.id] = 1 if question.default else 0
		
		questions_container.add_child(question_container)

func _on_slider_changed(value, value_label):
	value_label.text = str(value)
	var parent = value_label.get_parent()
	responses[parent.name] = value

func _on_spinbox_changed(value, question_id):
	responses[question_id] = value

func _on_checkbox_toggled(button_pressed, question_id):
	responses[question_id] = 1 if button_pressed else 0

func _on_submit_pressed():
	save_responses()
	var feedback = Label.new()
	feedback.text = "Thanks for submitting your data!"
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	for child in questions_container.get_children():
		child.queue_free()
	
	questions_container.add_child(feedback)
	submit_button.visible = false
	update_model_data()

func save_responses():
	DataStorage.add_survey_response(responses.duplicate())
	
	if "daily_stress" in responses:
		DataStorage.add_stress_score(responses["daily_stress"])

	if "mood_score" in responses:
		DataStorage.add_mood_score(responses["mood_score"])
	
	if "sleep_quality" in responses and "sleep_duration" in responses:
		# Normalize sleep quality to 0-1 range for the model
		var normalized_quality = float(responses["sleep_quality"]) / 5.0
		DataStorage.add_sleep_data(normalized_quality, responses["sleep_duration"])
	
	if "activity_social" in responses and responses["activity_social"] == 1:
		DataStorage.add_activity("Social Activity", 0.8, "social")
	
	if "activity_work" in responses and responses["activity_work"] == 1:
		DataStorage.add_activity("Work/Study", 0.7, "work")
	
	if "activity_relax" in responses and responses["activity_relax"] == 1:
		DataStorage.add_activity("Relaxation", 0.6, "relax")

func update_model_data():
	var model_data = DataStorage.get_model_input_data()
	print("Model input data: ", model_data)
	# Connect model here
