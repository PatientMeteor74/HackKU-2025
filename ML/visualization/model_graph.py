import numpy as np
import matplotlib.pyplot as plt
import joblib
import pandas as pd
from sklearn.preprocessing import StandardScaler

class MoodPredictionGraph:
    def __init__(self, model_path='mood_prediction_model.joblib', scaler_path='mood_prediction_scaler.joblib'):
        # Load the trained model and scaler
        self.model = joblib.load(model_path)
        self.scaler = joblib.load(scaler_path)
        
        # Extract model coefficients and intercept
        self.coefficients = self.model.coef_
        self.intercept = self.model.intercept_
        
        # Feature names from the training data
        self.feature_names = [
            'mood_score', 'mood_3day_avg', 'mood_7day_avg', 'mood_trend',
            'total_activity_score', 'social_intensity', 'work_intensity', 'relax_intensity',
            'is_social', 'is_working', 'is_relaxing', 'activity_3day_avg', 'activity_7day_avg',
            'activity_trend', 'sleep_quality', 'sleep_duration', 'is_short_sleep',
            'is_long_sleep', 'is_good_sleep', 'sleep_quality_3day_avg', 'sleep_duration_3day_avg',
            'sleep_quality_trend', 'sleep_duration_trend', 'hour', 'day_of_week',
            'is_weekend', 'has_location', 'latitude', 'longitude'
        ]
    
    def predict_mood_improvement(self, features_dict):
        """
        Use the extracted function to predict mood improvement
        
        Args:
            features_dict: Dictionary of feature names and values
            
        Returns:
            Predicted mood improvement value
        """
        # Create a feature array with the same structure as training data
        features = np.zeros(len(self.feature_names))
        for i, feature_name in enumerate(self.feature_names):
            if feature_name in features_dict:
                features[i] = features_dict[feature_name]
        
        # Scale the features
        features_scaled = self.scaler.transform([features])
        
        # Apply the prediction function
        prediction = self.intercept + np.dot(features_scaled, self.coefficients)
        
        return prediction[0]
    
    def get_model_function_string(self):
        """Return a string representation of the model function"""
        equation = f"f(x) = {self.intercept:.4f}"
        for i, coef in enumerate(self.coefficients):
            if abs(coef) > 0.001:  # Only show significant coefficients
                equation += f" + ({coef:.4f} × {self.feature_names[i]})"
        return equation
    
    def plot_feature_importance(self):
        """Create a bar chart of feature importance"""
        # Use absolute coefficient values as importance measure
        importance = np.abs(self.coefficients)
        
        # Get top 10 most important features
        indices = np.argsort(importance)[-10:]
        top_features = [self.feature_names[i] for i in indices]
        top_importance = importance[indices]
        
        # Create the bar chart
        plt.figure(figsize=(12, 6))
        plt.barh(top_features, top_importance)
        plt.xlabel('Absolute Coefficient Value')
        plt.title('Top 10 Features by Importance')
        plt.tight_layout()
        return plt
    
    def plot_prediction_distribution(self, data_sample):
        """
        Plot the distribution of predictions on a sample dataset
        
        Args:
            data_sample: DataFrame containing feature columns
        """
        # Prepare features
        X = data_sample[self.feature_names].fillna(0)
        
        # Scale features
        X_scaled = self.scaler.transform(X)
        
        # Get predictions
        predictions = self.model.predict(X_scaled)
        
        # Plot histogram
        plt.figure(figsize=(10, 6))
        plt.hist(predictions, bins=20, alpha=0.7)
        plt.axvline(x=0, color='r', linestyle='--')
        plt.xlabel('Predicted Mood Improvement')
        plt.ylabel('Frequency')
        plt.title('Distribution of Predicted Mood Improvements')
        plt.grid(True, alpha=0.3)
        return plt

# Example usage
if __name__ == "__main__":
    # Create graph object
    graph = MoodPredictionGraph()
    
    # Print the model function
    print("Extracted Model Function:")
    print(graph.get_model_function_string())
    
    # Example prediction
    example_features = {
        'mood_score': 0.5,
        'sleep_duration': 7.5,
        'sleep_quality': 0.7,
        'is_weekend': 1,
        'total_activity_score': 0.6
    }
    prediction = graph.predict_mood_improvement(example_features)
    print(f"\nPredicted mood improvement: {prediction:.4f}")
    
    # Example plot (commented out since we don't have sample data here)
    # Plot feature importance
    plt.figure(1)
    graph.plot_feature_importance()
    plt.savefig('feature_importance.png')
    
    # If we had sample data:
    # sample_data = pd.read_csv('sample_data.csv')
    # graph.plot_prediction_distribution(sample_data)
    # plt.savefig('prediction_distribution.png') 