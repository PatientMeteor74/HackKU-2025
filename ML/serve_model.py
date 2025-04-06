from flask import Flask, request, jsonify
import joblib
import os
import numpy as np
# Code based on https://github.com/DanielRJohnson/hackku-example-ml-project/blob/main/backend/serve_model.py

def do_mood_prediction():
   
    model_path = os.path.dirname(__file__) + "/training/models/mood_prediction_model.joblib"
    scaler_path = os.path.dirname(__file__) + "/training/models/target_scaler.joblib"
    
    model = joblib.load(model_path)
    scaler = joblib.load(scaler_path)
    
    data = request.json
    
    print("Received JSON data:", data)

    if not isinstance(data, dict):
        return jsonify({"error": "Data must be a JSON object"}), 400
        
    try:
        # Convert input data to format needed by model
        input_features = np.array([list(data.values())])
        
        # Make prediction and scale back to original range
        prediction = model.predict(input_features)
        if scaler:
            prediction = scaler.inverse_transform(prediction.reshape(-1, 1)).flatten()
            
        # Return prediction as JSON
        return jsonify({
            "prediction": float(prediction[0]),
            "status": "success"
        }), 200
        
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
print(do_mood_prediction())