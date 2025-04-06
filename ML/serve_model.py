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
        
        # Set paths to model files
        model_path = os.path.join(project_root, "mood_prediction_model.joblib")
        scaler_path = os.path.join(project_root, "target_scaler.joblib")
        
        # Load model and scaler
        model = joblib.load(model_path)
        
        try:
            scaler = joblib.load(scaler_path)
        except:
            scaler = None
        
        # Create a dataframe with only the required features
        # The model's pipeline will handle missing values through imputation
        df = pd.DataFrame([{
            "DAILY_STRESS": float(input_data.get("DAILY_STRESS")) if "DAILY_STRESS" in input_data else None,
            "FLOW": float(input_data.get("FLOW")) if "FLOW" in input_data else None,
            "TODO_COMPLETED": float(input_data.get("TODO_COMPLETED")) if "TODO_COMPLETED" in input_data else None,
            "SLEEP_HOURS": float(input_data.get("SLEEP_HOURS")) if "SLEEP_HOURS" in input_data else None,
            "GENDER": str(input_data.get("GENDER")) if "GENDER" in input_data else None,
            "AGE": input_data.get("AGE") if "AGE" in input_data else None
        }])

        # Handle AGE as a category if it's numeric
        if isinstance(df["AGE"].iloc[0], (int, float)) and df["AGE"].iloc[0] is not None:
            if df["AGE"].iloc[0] < 20:
                df["AGE"] = "Under 20"
            elif df["AGE"].iloc[0] < 35:
                df["AGE"] = "20 to 35"
            elif df["AGE"].iloc[0] < 50:
                df["AGE"] = "36 to 50"
            else:
                df["AGE"] = "Above 50"
        
        # Make prediction using the original model
        try:
            prediction = model.predict(df)
            
            # Scale back to original range if needed
            if scaler:
                prediction = scaler.inverse_transform(prediction.reshape(-1, 1)).flatten()
            
            # Raw score from model (typically in 200-800 range)
            raw_score = float(prediction[0])
            
            # Normalize to 0-5 scale
            # Assuming dataset range of 200-800
            min_score = 200
            max_score = 800
            normalized_score = 5 * (raw_score - min_score) / (max_score - min_score)
            normalized_score = max(0, min(5, normalized_score))  # Ensure it's in range 0-5
            
            # Return prediction as JSON
            message = ""
            if normalized_score < 1.5:
                message = "Your predicted well-being score is low. Consider reducing stress and improving sleep."
            elif normalized_score < 3.5:
                message = "Your predicted well-being score is moderate. You're doing okay, but there's room for improvement."
            else:
                message = "Your predicted well-being score is high. Keep up the good work!"
                
            return json.dumps({
                "prediction": round(normalized_score, 2),
                "raw_score": round(raw_score, 2),
                "message": message,
                "status": "success"
            })
            
        except Exception as e:
            # If model prediction fails, fall back to our custom calculation
            daily_stress = float(input_data.get("DAILY_STRESS", 0))
            flow = float(input_data.get("FLOW", 0))
            todo_completed = float(input_data.get("TODO_COMPLETED", 0))
            sleep_hours = float(input_data.get("SLEEP_HOURS", 0))
            
            # Stress reduces well-being (inverse relationship)
            stress_component = max(0, 10 - daily_stress * 2)
            
            # Flow state is good for well-being
            flow_component = flow * 2
            
            # Completing tasks is good for well-being
            todo_component = todo_completed / 10
            
            # Sleep is critical for well-being
            if sleep_hours < 5:
                sleep_component = sleep_hours * 1.5
            elif sleep_hours <= 8:
                sleep_component = 7.5 + (sleep_hours - 5) * 0.5
            else:
                sleep_component = 9 - (sleep_hours - 8) * 0.5
            
            # Calculate weighted score (0-10 scale)
            raw_score = (
                stress_component * 0.35 +
                flow_component * 0.25 +
                todo_component * 0.15 +
                sleep_component * 0.25
            )
            
            # Normalize to 0-5 scale
            normalized_score = raw_score * 0.5
            
            # Add message based on prediction value
            message = ""
            if normalized_score < 1.5:
                message = "Your predicted well-being score is low. Consider reducing stress and improving sleep."
            elif normalized_score < 3.5:
                message = "Your predicted well-being score is moderate. You're doing okay, but there's room for improvement."
            else:
                message = "Your predicted well-being score is high. Keep up the good work!"
                
            return json.dumps({
                "prediction": round(normalized_score, 2),
                "message": message,
                "status": "success",
                "note": "Fallback calculation used due to error: " + str(e)
            })
    
    except Exception as e:
        return json.dumps({"error": str(e)})

# If called directly (not imported), run prediction with args
if __name__ == "__main__":
    result = do_mood_prediction()
    print(result)