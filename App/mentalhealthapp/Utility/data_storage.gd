extends Node

const SAVE_PATH = "user://mental_health_data.json"
# Default empty data structure
var user_data = {
	"survey_responses": [],
	"mood_scores": [],
	"sleep_data": [],
	"activities": [],
	"flow_sessions": [],
	"todos": [],
	"user_profile": {
		"gender": "",
		"age": 0
	}
}

signal data_updated
var active_flow_session = null

func _ready():
	load_data()

# Save all data to disk
func save_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(user_data, "  "))
		file.close()
		emit_signal("data_updated")
		return true
	return false

# Load data from disk
func load_data():
	if not FileAccess.file_exists(SAVE_PATH):
		# If file doesn't exist, initialize with empty data
		save_data()
		return
		
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file:
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var error = json.parse(json_text)
		
		if error == OK:
			user_data = json.data
			if not user_data.has("flow_sessions"):
				user_data["flow_sessions"] = []
			if not user_data.has("todos"):
				user_data["todos"] = []
			if not user_data.has("user_profile"):
				user_data["user_profile"] = {"gender": "", "age": 0}
			emit_signal("data_updated")
		else:
			print("JSON Parse Error: ", json.get_error_message(), " at line ", json.get_error_line())

func set_user_profile(gender, age):
	user_data["user_profile"]["gender"] = gender
	user_data["user_profile"]["age"] = age
	save_data()

func add_survey_response(response_data):
	# Add timestamp to response data
	response_data["timestamp"] = Time.get_unix_time_from_system()
	user_data["survey_responses"].append(response_data)
	save_data()

func add_stress_score(score, notes=""):
	var stress_entry = {
		"score": score,
		"notes": notes,
		"timestamp": Time.get_unix_time_from_system()
	}
	if not user_data.has("daily_stress"):
		user_data["daily_stress"] = []
	
	user_data["daily_stress"].append(stress_entry)
	save_data()

func add_mood_score(score, notes=""):
	var mood_entry = {
		"score": score,
		"notes": notes,
		"timestamp": Time.get_unix_time_from_system()
	}
	user_data["mood_scores"].append(mood_entry)
	save_data()

func add_sleep_data(quality, duration, notes=""):
	var sleep_entry = {
		"quality": quality,
		"duration": duration,
		"notes": notes,
		"timestamp": Time.get_unix_time_from_system()
	}
	user_data["sleep_data"].append(sleep_entry)
	save_data()

func add_activity(name, intensity, category, notes=""):
	var activity_entry = {
		"name": name,
		"intensity": intensity,
		"category": category,
		"notes": notes,
		"timestamp": Time.get_unix_time_from_system()
	}
	user_data["activities"].append(activity_entry)
	save_data()

func add_todo(title, description="", due_date=0):
	var todo_entry = {
		"title": title,
		"description": description,
		"due_date": due_date,
		"completed": false,
		"creation_timestamp": Time.get_unix_time_from_system(),
		"completion_timestamp": 0
	}
	user_data["todos"].append(todo_entry)
	save_data()
	return user_data["todos"].size() - 1  # Return index of the new todo

func complete_todo(todo_index):
	if todo_index >= 0 and todo_index < user_data["todos"].size():
		user_data["todos"][todo_index]["completed"] = true
		user_data["todos"][todo_index]["completion_timestamp"] = Time.get_unix_time_from_system()
		save_data()
		return true
	return false

func start_flow_session(activity_name, category):
	if active_flow_session != null:
		end_flow_session()
	
	active_flow_session = {
		"activity_name": activity_name,
		"category": category,
		"start_time": Time.get_unix_time_from_system(),
		"end_time": null,
		"duration_minutes": 0
	}
	
	print("Started flow session")
	return active_flow_session

func end_flow_session():
	if active_flow_session == null:
		return null
	
	var end_time = Time.get_unix_time_from_system()
	active_flow_session["end_time"] = end_time
	var duration_seconds = end_time - active_flow_session["start_time"]
	active_flow_session["duration_minutes"] = duration_seconds / 60.0
	
	user_data["flow_sessions"].append(active_flow_session.duplicate())
	
	print("Ended flow session for: ", active_flow_session["activity_name"], ", Duration: ", active_flow_session["duration_minutes"], " minutes")
	
	var completed_session = active_flow_session
	active_flow_session = null
	save_data()
	
	return completed_session

func get_active_flow_session():
	return active_flow_session

func get_model_input_data():
	var input_features = {}
	
	input_features["Timestamp"] = Time.get_datetime_string_from_system()
	
	# DAILY_STRESS
	if user_data.has("daily_stress") and user_data["daily_stress"].size() > 0:
		input_features["DAILY_STRESS"] = user_data["daily_stress"][-1]["score"]
	else:
		input_features["DAILY_STRESS"] = 3
	
	# FLOW
	var flow_minutes = 0
	var current_time = Time.get_unix_time_from_system()
	if user_data.has("flow_sessions"):
		for session in user_data["flow_sessions"]:
			if current_time - session["end_time"] < 86400: # Last 24 hours
				flow_minutes += session["duration_minutes"]
	if active_flow_session != null:
		var active_flow_minutes = (current_time - active_flow_session["start_time"]) / 60.0
		flow_minutes += active_flow_minutes
	
	input_features["FLOW"] = flow_minutes
	
	# TODO_COMPLETED
	var completed_todos = 0
	if user_data.has("todos"):
		for todo in user_data["todos"]:
			if todo["completed"] and current_time - todo["completion_timestamp"] < 86400:
				completed_todos += 1
	
	input_features["TODO_COMPLETED"] = completed_todos
	
	# SLEEP_HOURS
	if user_data["sleep_data"].size() > 0:
		input_features["SLEEP_HOURS"] = user_data["sleep_data"][-1]["duration"]
	else:
		input_features["SLEEP_HOURS"] = 7  # Default to 7 hours if no data
	
	# GENDER and AGE from user profile
	input_features["GENDER"] = user_data["user_profile"]["gender"]
	input_features["AGE"] = user_data["user_profile"]["age"]
	
	# WORK_LIFE_BALANCE_SCORE - Use mood score as the balance score
	if user_data["mood_scores"].size() > 0:
		# Normalize mood score to 0-1 range (assuming mood is 1-5 scale)
		input_features["WORK_LIFE_BALANCE_SCORE"] = (user_data["mood_scores"][-1]["score"] - 1) / 4.0
	else:
		input_features["WORK_LIFE_BALANCE_SCORE"] = 0.5  # Default to middle value
	
	return input_features

# Clear all data (for testing or user reset)
func clear_data():
	user_data = {
		"survey_responses": [],
		"mood_scores": [],
		"sleep_data": [],
		"activities": [],
		"flow_sessions": [],
		"todos": [],
		"user_profile": {
			"gender": "",
			"age": 0
		}
	}
	active_flow_session = null
	save_data() 
