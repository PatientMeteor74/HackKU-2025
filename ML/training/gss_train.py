import numpy as np
import pandas as pd
import json, glob
import matplotlib.pyplot as plt
from sklearn.tree import DecisionTreeClassifier, DecisionTreeRegressor
from sklearn.ensemble import RandomForestClassifier, RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, f1_score, mean_squared_error, r2_score
from imblearn.under_sampling import RandomUnderSampler
import joblib
from sklearn.preprocessing import StandardScaler, OneHotEncoder
from sklearn.linear_model import LinearRegression
from sklearn.model_selection import TimeSeriesSplit

path = "/home/johnplatkowski/Documents/Projects/HackKU-2025/ML/data/"

gss_df = pd.read_sas(path + "GSS_sas/gss7222_r4.sas7bdat")
gss_data = []

# Select features for training
features = [
    # Mood features
    'mood_score',
    'mood_3day_avg',
    'mood_7day_avg',
    'mood_trend',
    
    # Activity features
    'total_activity_score',
    'social_intensity',
    'work_intensity',
    'relax_intensity',
    'is_social',
    'is_working',
    'is_relaxing',
    'activity_3day_avg',
    'activity_7day_avg',
    'activity_trend',
    
    # Sleep features
    'sleep_quality',
    'sleep_duration',
    'is_short_sleep',
    'is_long_sleep',
    'is_good_sleep',
    'sleep_quality_3day_avg',
    'sleep_duration_3day_avg',
    'sleep_quality_trend',
    'sleep_duration_trend',
    
    # Time features
    'hour',
    'day_of_week',
    'is_weekend',
    
    # Location features (if available)
    'has_location',
    'latitude',
    'longitude'
]

# Prepare data for training
X = gss_data[features].fillna(0)
y = gss_data['mood_improvement'].fillna(0)

# Split data to test trained data against untrained data
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.1, random_state=42)

# Scale features
scaler = StandardScaler()
X_train_scaled = scaler.fit_transform(X_train)
X_test_scaled = scaler.transform(X_test)

# Train model
model = LinearRegression()
model.fit(X_train_scaled, y_train)

# Evaluate model
y_train_pred = model.predict(X_train_scaled)
y_test_pred = model.predict(X_test_scaled)
train_score = r2_score(y_train, y_train_pred)
test_score = r2_score(y_test, y_test_pred)
train_rmse = np.sqrt(mean_squared_error(y_train, y_train_pred))
test_rmse = np.sqrt(mean_squared_error(y_test, y_test_pred))
test_y_intercept = model.intercept_
test_m = model.coef_

print(f"Training R^2 score: {train_score}")
print(f"Testing R^2 score: {test_score}")
print(f"Training RMSE: {train_rmse}")
print(f"Testing RMSE: {test_rmse}")
print(f"Model Function: f(x) = {test_m}X + {test_y_intercept}")

# Save model and scaler
joblib.dump(model, 'mood_prediction_model.joblib')
joblib.dump(scaler, 'mood_prediction_scaler.joblib')