from flask import Flask, request, jsonify
import joblib
import os
import numpy as np
import sys
import json
import pandas as pd
# Code based on https://github.com/DanielRJohnson/hackku-example-ml-project/blob/main/backend/serve_model.py

def do_mood_prediction(input_data=None):
    try:
        # If input_data is provided as argument, use it
        # Otherwise, check for JSON from command line
        if input_data is None:
            # Check if data is passed as command line argument
            if len(sys.argv) > 1:
                try:
                    input_data = json.loads(sys.argv[1])
                except json.JSONDecodeError:
                    return json.dumps({"error": "Invalid JSON input"})
            else:
                return json.dumps({"error": "No input data provided"})
        
        if not isinstance(input_data, dict):
            return json.dumps({"error": "Data must be a JSON object"})
            
        # Get project root (parent of ML folder)
        ml_dir = os.path.dirname(__file__)
        project_root = os.path.dirname(ml_dir)
        
        # Use the dummy model that works with 6 features
        model_path = os.path.join(project_root, "dummy_model.joblib")
        
        # Load model
        model = joblib.load(model_path)
        
        # Extract features and convert to numeric array
        features = np.array([
            float(input_data.get("DAILY_STRESS", 0)),
            float(input_data.get("FLOW", 0)),
            float(input_data.get("TODO_COMPLETED", 0)),
            float(input_data.get("SLEEP_HOURS", 0)),
            1.0 if str(input_data.get("GENDER", "")).lower() == "male" else 0.0,
            float(input_data.get("AGE", 0))
        ]).reshape(1, -1)
        
        # Make prediction
        prediction = model.predict(features)
        
        # The dummy model returns a hardcoded prediction, 
        # but for demonstration purposes, we'll scale it between 0 and 10
        # to represent a well-being score
        min_score = 0.0
        max_score = 10.0
        scaled_prediction = min_score + (max_score - min_score) * float(prediction[0])
        
        # Add message based on prediction value
        message = ""
        if scaled_prediction < 3:
            message = "Your predicted well-being score is low. Consider implementing stress reduction techniques."
        elif scaled_prediction < 7:
            message = "Your predicted well-being score is moderate. You're doing okay, but there's room for improvement."
        else:
            message = "Your predicted well-being score is high. Keep up the good work!"
        
        # Return result
        return json.dumps({
            "prediction": float(scaled_prediction),
            "message": message,
            "status": "success"
        })
    
    except Exception as e:
        return json.dumps({"error": str(e)})

# If called directly (not imported), run prediction with args
if __name__ == "__main__":
    result = do_mood_prediction()
    print(result)