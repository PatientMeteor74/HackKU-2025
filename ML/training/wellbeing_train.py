import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split, cross_val_score
from sklearn.metrics import mean_squared_error, r2_score
import joblib
from sklearn.preprocessing import StandardScaler, OneHotEncoder, MinMaxScaler
from sklearn.compose import ColumnTransformer
from sklearn.pipeline import Pipeline

path = "/home/johnplatkowski/Documents/Projects/HackKU-2025/ML/data/"

# Load data
df = pd.read_csv(path + "Wellbeing_and_lifestyle_data_Kaggle.csv")
df_selected = df[["Timestamp", "DAILY_STRESS", "FLOW", "TODO_COMPLETED", "SLEEP_HOURS", "GENDER", "AGE", "WORK_LIFE_BALANCE_SCORE"]]

# Prepare data for training
df_selected_nonan = df_selected.dropna()

# Drop Timestamp column and target variable
X = df_selected_nonan.drop(columns=["WORK_LIFE_BALANCE_SCORE", "Timestamp"])
y = df_selected_nonan["WORK_LIFE_BALANCE_SCORE"]

# Scale the target variable to 0-1 range
y_scaler = MinMaxScaler()
y_scaled = y_scaler.fit_transform(y.values.reshape(-1, 1)).flatten()

# Identify categorical columns
categorical_cols = X.select_dtypes(include=['object', 'category']).columns.tolist()
numeric_cols = X.select_dtypes(include=['int64', 'float64']).columns.tolist()

# Create preprocessing pipeline
preprocessor = ColumnTransformer(
    transformers=[
        ('num', StandardScaler(), numeric_cols),
        ('cat', OneHotEncoder(handle_unknown='ignore'), categorical_cols)
    ]
)

# Create the full pipeline with preprocessing and model
model_pipeline = Pipeline(steps=[
    ('preprocessor', preprocessor),
    ('regressor', RandomForestRegressor(
        n_estimators=100,
        max_depth=8,
        min_samples_split=5,
        min_samples_leaf=2,   
        random_state=42
    ))
])

# Split data to test trained data against untrained data
X_train, X_test, y_train_scaled, y_test_scaled = train_test_split(X, y_scaled, test_size=0.2, random_state=42)

# Train regression model
model_pipeline.fit(X_train, y_train_scaled)

# Evaluate model on scaled data
y_train_scaled_pred = model_pipeline.predict(X_train)
y_test_scaled_pred = model_pipeline.predict(X_test)

# Calculate metrics on scaled data (0-1 range)
train_score = r2_score(y_train_scaled, y_train_scaled_pred)
test_score = r2_score(y_test_scaled, y_test_scaled_pred)
train_rmse = np.sqrt(mean_squared_error(y_train_scaled, y_train_scaled_pred))
test_rmse = np.sqrt(mean_squared_error(y_test_scaled, y_test_scaled_pred))

print(f"Training R^2 score: {train_score}")
print(f"Test R^2 score: {test_score}")
print(f"Training RMSE: {train_rmse}")
print(f"Test RMSE: {test_rmse}")

# Save model and scaler for later use
joblib.dump(model_pipeline, 'mood_prediction_model.joblib')
joblib.dump(y_scaler, 'target_scaler.joblib')