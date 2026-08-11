import pandas as pd
import csv

# --- Configuration ---
# The output file from the awk step
intermediate_filtered_file = 'intermediate_filtered_data.csv'
# The original file with allotment codes and their names
allotment_names_file = 'CT_Allotments.csv'
# The new file with Survey Record Numbers
survey_record_file = 'SR_Parcel_WC.txt'
# Your final output file name
final_output_file = 'final_extracted_allotment_data_full.csv' # Keeps the same filename, will overwrite

# --- Step 1: Load the intermediate filtered data (from awk) ---
try:
    df_filtered = pd.read_csv(
        intermediate_filtered_file,
        header=None,
        names=['PropertyDiagramNumber', 'UniqueIdNumber', 'AllotmentAreaCode'],
        sep=',',
        quotechar='"'
    )
    df_filtered['AllotmentAreaCode'] = df_filtered['AllotmentAreaCode'].astype(str).str.strip('"')
    df_filtered['PropertyDiagramNumber'] = df_filtered['PropertyDiagramNumber'].astype(str)
    df_filtered['UniqueIdNumber'] = df_filtered['UniqueIdNumber'].astype(str).str.strip()


    print(f"Loaded {len(df_filtered)} filtered rows from awk output.")

except FileNotFoundError:
    print(f"Error: The file '{intermediate_filtered_file}' was not found. "
          "Please make sure it's in the same directory as the script, or provide the full path.")
    exit()
except Exception as e:
    print(f"An error occurred loading the filtered data: {e}")
    exit()


# --- Step 2: Load the Allotment Area Names ---
try:
    df_names = pd.read_csv(
        allotment_names_file,
        header=0,
        names=['AllotmentAreaCode', 'AllotmentName'],
        sep=','
    )
    df_names['AllotmentAreaCode'] = df_names['AllotmentAreaCode'].astype(str).str.strip()

    original_names_rows_allotment = len(df_names)
    df_names.drop_duplicates(subset=['AllotmentAreaCode'], keep='first', inplace=True)
    print(f"Cleaned Allotment Names: Removed {original_names_rows_allotment - len(df_names)} duplicate AllotmentAreaCode entries.")
    print(f"Loaded {len(df_names)} unique allotment names for merging.")

except FileNotFoundError:
    print(f"Error: The file '{allotment_names_file}' was not found. "
          "Please make sure it's in the same directory as the script, or provide the full path.")
    exit()
except Exception as e:
    print(f"An error occurred loading allotment names: {e}")
    exit()


# --- Step 3: Load the Survey Record Data ---
try:
    df_survey = pd.read_csv(
        survey_record_file,
        header=0,
        names=['SurveyRecordNumber', 'UniqueIdNumber'],
        sep=','
    )
    df_survey['UniqueIdNumber'] = df_survey['UniqueIdNumber'].astype(str).str.strip()

    # --- NEW IMPORTANT LINE: Remove duplicates from df_survey BEFORE merging ---
    # This ensures each UniqueIdNumber from the survey file has only one associated record
    original_survey_rows = len(df_survey)
    df_survey.drop_duplicates(subset=['UniqueIdNumber'], keep='first', inplace=True)
    print(f"Cleaned Survey Records: Removed {original_survey_rows - len(df_survey)} duplicate UniqueIdNumber entries.")

    # Extract SR_Year from SurveyRecordNumber
    year_parts = df_survey['SurveyRecordNumber'].str.split('/', expand=True)
    df_survey['SR_Year_str'] = year_parts[1] if 1 in year_parts.columns else pd.NA

    df_survey['SR_Year'] = pd.to_numeric(df_survey['SR_Year_str'], errors='coerce').astype(pd.Int64Dtype())
    df_survey.drop(columns=['SR_Year_str'], inplace=True)

    print(f"Loaded {len(df_survey)} unique survey record entries for merging.")

except FileNotFoundError:
    print(f"Error: The file '{survey_record_file}' was not found. "
          "Please make sure it's in the same directory as the script, or provide the full path.")
    exit()
except Exception as e:
    print(f"An error occurred loading survey record data: {e}")
    exit()


# --- Step 4: Merge (Join) the Dataframes (First Merge) ---
df_merged_data = pd.merge(
    df_filtered,
    df_names[['AllotmentAreaCode', 'AllotmentName']],
    on='AllotmentAreaCode',
    how='left'
)

# --- Step 5: Extract Year from PropertyDiagramNumber and convert to nullable integer ---
year_parts_sg = df_merged_data['PropertyDiagramNumber'].str.strip('"').str.split('/', expand=True)
df_merged_data['Year_str'] = year_parts_sg[1] if 1 in year_parts_sg.columns else pd.NA

df_merged_data['Year'] = pd.to_numeric(df_merged_data['Year_str'], errors='coerce').astype(pd.Int64Dtype())
df_merged_data.drop(columns=['Year_str'], inplace=True)


# --- Step 6: Merge with Survey Record Data (Second Merge) ---
df_final_output = pd.merge(
    df_merged_data,
    df_survey[['UniqueIdNumber', 'SurveyRecordNumber', 'SR_Year']],
    on='UniqueIdNumber',
    how='left'
)


# --- Step 7: Select and Reorder Final Columns ---
df_final_output = df_final_output[[
    'PropertyDiagramNumber',
    'UniqueIdNumber',
    'AllotmentAreaCode',
    'AllotmentName',
    'Year', # Year from PropertyDiagramNumber (SG Year)
    'SurveyRecordNumber',
    'SR_Year' # Year from SurveyRecordNumber
]]

# --- Step 8: Save the final output ---
df_final_output.to_csv(
    final_output_file,
    index=False,
    quoting=csv.QUOTE_MINIMAL
)

print(f"\nProcess complete! Successfully created '{final_output_file}'.")
print(f"Final output file contains {len(df_final_output)} rows with all requested columns.")
