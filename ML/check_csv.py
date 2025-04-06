import pandas as pd
import os

# Get the path to the CSV file
file_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "ML", "data", "Wellbeing_and_lifestyle_data_Kaggle.csv")

# Read just the first few rows
df = pd.read_csv(file_path)

# Print the column names
print("CSV File Columns:")
for i, col in enumerate(df.columns):
    print(f"{i+1}. {col}")

# Print a sample row to see the data
print("\nSample Data Row:")
print(df.iloc[0].to_dict()) 