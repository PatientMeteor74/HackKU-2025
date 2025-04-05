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

# Load and process mood data
mood_dfs_json = glob.glob(path + "Mood/*.json")
mood_dfs = []
for file in mood_dfs_json:
    with open(file, 'r') as f:
        data = json.load(f)
    
    # Skip empty files
    if not data:
        print(f"Warning: Empty JSON file found: {file}")
        continue
        
    mood_df = pd.DataFrame(data)
    
    # Ensure all required columns exist
    required_columns = ['happy', 'sad', 'happyornot', 'sadornot', 'location', 'resp_time']
    for col in required_columns:
        if col not in mood_df.columns:
            print(f"Warning: Column {col} not found in {file}")
            continue
    
    # Extract user ID from filename (e.g., "Mood_u00.json" -> "u00")
    uid = file.split('/')[-1].split('.')[0].split('_')[1]
    mood_df['uid'] = uid
    
    # Convert string values to numeric where appropriate
    mood_df['happy'] = pd.to_numeric(mood_df['happy'], errors='coerce')
    mood_df['sad'] = pd.to_numeric(mood_df['sad'], errors='coerce')
    mood_df['happyornot'] = pd.to_numeric(mood_df['happyornot'], errors='coerce')
    mood_df['sadornot'] = pd.to_numeric(mood_df['sadornot'], errors='coerce')
    
    # Create composite mood score (normalized to 0-1 range)
    # Higher happy and lower sad values indicate better mood
    mood_df['mood_score'] = ((mood_df['happy'] / 4) - (mood_df['sad'] / 4) + 1) / 2
    
    # Process location data
    mood_df['has_location'] = mood_df['location'] != 'Unknown'
    mood_df['latitude'] = mood_df['location'].apply(
        lambda x: float(x.split(',')[0]) if isinstance(x, str) and x != 'Unknown' 
        else float(x) if isinstance(x, (int, float)) 
        else None
    )
    mood_df['longitude'] = mood_df['location'].apply(
        lambda x: float(x.split(',')[1]) if isinstance(x, str) and x != 'Unknown' 
        else None
    )
    
    # Convert timestamp
    mood_df['datetime'] = pd.to_datetime(mood_df['resp_time'], unit='s')
    
    mood_dfs.append(mood_df)

mood_data = pd.concat(mood_dfs, ignore_index=True)

# Load and process activity data
activity_dfs_json = glob.glob(path + "Activity/*.json")
activity_dfs = []
for file in activity_dfs_json:
    with open(file, "r") as f:
        data = json.load(f)
    
    # Skip empty files
    if not data:
        print(f"Warning: Empty JSON file found: {file}")
        continue
        
    activity_df = pd.DataFrame(data)
    
    # Extract user ID from filename (e.g., "Activity_u00.json" -> "u00")
    uid = file.split('/')[-1].split('.')[0].split('_')[1]
    activity_df['uid'] = uid
    
    # Convert string values to numeric where appropriate
    numeric_columns = ['Social2', 'null', 'other_relaxing', 'other_working', 'relaxing', 'working']
    for col in numeric_columns:
        if col in activity_df.columns:
            activity_df[col] = pd.to_numeric(activity_df[col], errors='coerce')
    
    # Convert timestamp
    activity_df['datetime'] = pd.to_datetime(activity_df['resp_time'], unit='s')
    
    # Process location data
    if 'location' in activity_df.columns:
        activity_df['has_location'] = ~activity_df['location'].isin(['Unknown', 'null'])
        activity_df['latitude'] = activity_df['location'].apply(
            lambda x: float(x.split(',')[0]) if isinstance(x, str) and x not in ['Unknown', 'null'] and ',' in x
            else float(x) if isinstance(x, (int, float)) 
            else None
        )
        activity_df['longitude'] = activity_df['location'].apply(
            lambda x: float(x.split(',')[1]) if isinstance(x, str) and x not in ['Unknown', 'null'] and ',' in x
            else None
        )
    else:
        activity_df['has_location'] = False
        activity_df['latitude'] = None
        activity_df['longitude'] = None
    
    # Create activity categories with safe column access
    activity_df['is_social'] = activity_df['Social2'].notna().astype(int) if 'Social2' in activity_df.columns else 0
    activity_df['is_working'] = activity_df['working'].notna().astype(int) if 'working' in activity_df.columns else 0
    activity_df['is_relaxing'] = activity_df['relaxing'].notna().astype(int) if 'relaxing' in activity_df.columns else 0
    
    # Create activity intensity scores with safe column access
    activity_df['social_intensity'] = activity_df['Social2'].fillna(0) if 'Social2' in activity_df.columns else 0
    activity_df['work_intensity'] = activity_df['working'].fillna(0) if 'working' in activity_df.columns else 0
    activity_df['relax_intensity'] = activity_df['relaxing'].fillna(0) if 'relaxing' in activity_df.columns else 0
    
    # Calculate total activity score
    activity_df['total_activity_score'] = (
        activity_df['social_intensity'] + 
        activity_df['work_intensity'] + 
        activity_df['relax_intensity']
    ) / 3
    
    activity_dfs.append(activity_df)

activity_data = pd.concat(activity_dfs, ignore_index=True)

# Load and process sleep data
sleep_dfs_json = glob.glob(path + "Sleep/*.json")
sleep_dfs = []
for file in sleep_dfs_json:
    with open(file, "r") as f:
        data = json.load(f)
    
    # Skip empty files
    if not data:
        print(f"Warning: Empty JSON file found: {file}")
        continue
        
    sleep_df = pd.DataFrame(data)
    
    # Extract user ID from filename (e.g., "Sleep_u00.json" -> "u00")
    uid = file.split('/')[-1].split('.')[0].split('_')[1]
    sleep_df['uid'] = uid
    
    # Convert string values to numeric where appropriate
    numeric_columns = ['hour', 'rate', 'social']
    for col in numeric_columns:
        if col in sleep_df.columns:
            sleep_df[col] = pd.to_numeric(sleep_df[col], errors='coerce')
    
    # Process location data
    sleep_df['has_location'] = sleep_df['location'] != 'Unknown'
    sleep_df['latitude'] = sleep_df['location'].apply(
        lambda x: float(x.split(',')[0]) if isinstance(x, str) and x != 'Unknown' 
        else float(x) if isinstance(x, (int, float)) 
        else None
    )
    sleep_df['longitude'] = sleep_df['location'].apply(
        lambda x: float(x.split(',')[1]) if isinstance(x, str) and x != 'Unknown' 
        else None
    )
    
    # Convert timestamp
    sleep_df['datetime'] = pd.to_datetime(sleep_df['resp_time'], unit='s')
    
    # Create sleep quality features
    sleep_df['sleep_quality'] = sleep_df['rate'].fillna(0)
    sleep_df['sleep_duration'] = sleep_df['hour'].fillna(0)
    
    # Create sleep patterns
    sleep_df['is_short_sleep'] = (sleep_df['sleep_duration'] < 6).astype(int)
    sleep_df['is_long_sleep'] = (sleep_df['sleep_duration'] > 8).astype(int)
    sleep_df['is_good_sleep'] = (sleep_df['sleep_quality'] >= 3).astype(int)
    
    sleep_dfs.append(sleep_df)

sleep_data = pd.concat(sleep_dfs, ignore_index=True)

# Create time-based features
sleep_data['hour'] = sleep_data['datetime'].dt.hour
sleep_data['day_of_week'] = sleep_data['datetime'].dt.dayofweek
sleep_data['is_weekend'] = sleep_data['day_of_week'].isin([5, 6]).astype(int)

# Create sleep-based features
sleep_data = sleep_data.sort_values(['uid', 'datetime'])
sleep_data['sleep_quality_3day_avg'] = sleep_data.groupby('uid')['sleep_quality'].rolling(window=3).mean().reset_index(0, drop=True)
sleep_data['sleep_duration_3day_avg'] = sleep_data.groupby('uid')['sleep_duration'].rolling(window=3).mean().reset_index(0, drop=True)
sleep_data['sleep_quality_trend'] = sleep_data.groupby('uid')['sleep_quality'].diff()
sleep_data['sleep_duration_trend'] = sleep_data.groupby('uid')['sleep_duration'].diff()

# Load and process PHQ-9 survey data
phq9_data = pd.read_csv(path + 'survey/PHQ-9.csv')
phq9_mapping = {
    'Not at all': 3,
    'Several days': 2,
    'More than half the days': 1,
    'Nearly every day': 0
}
phq9_response_mapping = {
    'Not difficult at all': 3,
    'Somewhat difficult': 2,
    'Very difficult': 1,
    'Extremely difficult': 0
}

# Apply the mapping to each column
for col in phq9_data.columns[2:-1]:  # Assuming Response is the last column
    phq9_data[col] = phq9_data[col].map(phq9_mapping) / 3
phq9_data['Response'] = phq9_data['Response'].map(phq9_response_mapping) / 3

# Create time-based features
mood_data['hour'] = mood_data['datetime'].dt.hour
mood_data['day_of_week'] = mood_data['datetime'].dt.dayofweek
mood_data['is_weekend'] = mood_data['day_of_week'].isin([5, 6]).astype(int)

# Create mood-based features
mood_data = mood_data.sort_values(['uid', 'datetime'])
mood_data['mood_3day_avg'] = mood_data.groupby('uid')['mood_score'].rolling(window=3).mean().reset_index(0, drop=True)
mood_data['mood_7day_avg'] = mood_data.groupby('uid')['mood_score'].rolling(window=7).mean().reset_index(0, drop=True)
mood_data['mood_trend'] = mood_data.groupby('uid')['mood_score'].diff()

# Create time-based features
activity_data['hour'] = activity_data['datetime'].dt.hour
activity_data['day_of_week'] = activity_data['datetime'].dt.dayofweek
activity_data['is_weekend'] = activity_data['day_of_week'].isin([5, 6]).astype(int)

# Create activity-based features
activity_data = activity_data.sort_values(['uid', 'datetime'])
activity_data['activity_3day_avg'] = activity_data.groupby('uid')['total_activity_score'].rolling(window=3).mean().reset_index(0, drop=True)
activity_data['activity_7day_avg'] = activity_data.groupby('uid')['total_activity_score'].rolling(window=7).mean().reset_index(0, drop=True)
activity_data['activity_trend'] = activity_data.groupby('uid')['total_activity_score'].diff()

# Merge all datasets
merged_data = pd.merge_asof(
    mood_data.sort_values('datetime'),
    activity_data.sort_values('datetime'),
    on='datetime',
    by='uid',
    direction='nearest'
)

merged_data = pd.merge_asof(
    merged_data.sort_values('datetime'),
    sleep_data.sort_values('datetime'),
    on='datetime',
    by='uid',
    direction='nearest'
)

# Create target variables
merged_data['next_day_mood'] = merged_data.groupby('uid')['mood_score'].shift(-1)
merged_data['mood_improvement'] = merged_data['next_day_mood'] - merged_data['mood_score']
merged_data['mood_category'] = pd.cut(merged_data['mood_score'], bins=[-float('inf'), 0.33, 0.66, float('inf')], 
                                    labels=['low', 'medium', 'high'])

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
X = merged_data[features].fillna(0)
y = merged_data['mood_improvement'].fillna(0)

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