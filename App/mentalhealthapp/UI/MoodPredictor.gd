extends Node
class_name MoodPredictor

signal prediction_completed(result)

# Path to the Python prediction script directly
var python_script_name = "godot_predictor.py" 
var python_executable = "python"

# Call the ML model to predict mood based on input features
func predict_mood(features_dict):
	# Convert features dictionary to JSON with proper escaping
	var json = JSON.new()
	var json_text = JSON.stringify(features_dict)
	
	# Double-escape special characters for command line
	# Replace any backslashes with double backslashes
	json_text = json_text.replace("\\", "\\\\")
	# Escape double quotes 
	json_text = json_text.replace("\"", "\\\"")
	
	print("Sending JSON: ", json_text)
	
	# Create array to store output
	var output = []
	
	# Get the correct path to the ML directory (at project root, not in App)
	var app_dir = OS.get_executable_path().get_base_dir()
	# Need to go up two levels: from /App/mentalhealthapp to project root
	var project_root = app_dir.get_base_dir().get_base_dir()
	var script_path = project_root + "/ML/" + python_script_name
	
	print("App directory: ", app_dir)
	print("Project root: ", project_root)
	print("Using script path: ", script_path)
	
	# Create a temporary JSON file instead of passing directly via command line
	var temp_json_path = project_root + "/temp_input.json"
	var file = FileAccess.open(temp_json_path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(features_dict))
		file.close()
		print("Wrote JSON to temporary file: " + temp_json_path)
		
		# Execute the Python script with the file path
		var exit_code = OS.execute(python_executable, [script_path, temp_json_path], output, true)
		
		# Parse the JSON result
		if exit_code == 0 and output.size() > 0:
			var result = JSON.parse_string(output[0])
			emit_signal("prediction_completed", result)
			return result
		else:
			var error = {"error": "Execution failed", "exit_code": exit_code}
			if output.size() > 0:
				error["message"] = output[0]
			emit_signal("prediction_completed", error)
			return error
	else:
		var error = {"error": "Failed to create temporary JSON file"}
		emit_signal("prediction_completed", error)
		return error

# Get absolute path for the script based on the project directory
func get_absolute_path(relative_path):
	# Convert the resource path to a global path
	if relative_path.begins_with("res://"):
		relative_path = relative_path.substr(6) # Remove res:// prefix
	
	# Get the project directory
	var project_dir = OS.get_executable_path().get_base_dir()
	
	# If running from the editor, use a different approach
	if OS.has_feature("editor"):
		project_dir = ProjectSettings.globalize_path("res://")
	else:
		# For exported project, we need to go up from the executable location
		# This may need adjustment depending on your export structure
		project_dir = project_dir.path_join("../..")
	
	print("Project directory: ", project_dir)
	
	# Combine project dir with the relative path
	var full_path = project_dir.path_join(relative_path)
	
	print("Full path: ", full_path)
	return full_path

# Example usage:
# var predictor = MoodPredictor.new()
# var features = {
#     "hours_slept": 7.5,
#     "stress_level": 3,
#     "exercise_minutes": 30,
#     "social_time_hours": 2
# }
# var result = predictor.predict_mood(features)
# print("Predicted mood: ", result.prediction) 
