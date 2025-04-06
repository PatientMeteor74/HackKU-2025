#!/usr/bin/env python
import sys
import json
from serve_model import do_mood_prediction

"""
Simple wrapper script to call the ML model from Godot using OS.execute
Usage from Godot:
   var output = []
   var exit_code = OS.execute("python", ["path/to/godot_predictor.py", json_file_path], output)
   var prediction_result = JSON.parse_string(output[0])
"""

if __name__ == "__main__":
    if len(sys.argv) > 1:
        # Get the JSON input from command line argument
        try:
            input_file_path = sys.argv[1]
            
            # Check if argument is a file path
            if input_file_path.endswith('.json'):
                # Read from file
                try:
                    with open(input_file_path, 'r') as f:
                        input_data = json.load(f)
                    result = do_mood_prediction(input_data)
                    print(result)  # Print to stdout for Godot to capture
                except Exception as e:
                    print(json.dumps({"error": f"Error reading file: {str(e)}"}))
            else:
                # Try to parse the argument directly as JSON
                try:
                    input_data = json.loads(sys.argv[1])
                    result = do_mood_prediction(input_data)
                    print(result)  # Print to stdout for Godot to capture
                except json.JSONDecodeError as e:
                    print(json.dumps({"error": "Invalid JSON input", "details": str(e)}))
        except Exception as e:
            print(json.dumps({"error": f"Unexpected error: {str(e)}"}))
    else:
        print(json.dumps({"error": "No input data provided"})) 