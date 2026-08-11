import pandas as pd
import csv


# --- Configuration ---

large_data_file = "Thesis\\Data\\SG Databse\\SGNO_Parcel_WC.txt"

allotment_names_file = 'CT_Allotments.csv'

output_filtered_file = 'final_extracted_data_with_names.csv'


# --- Step 1: Load Allotment Area Names and Codes ---

# This DataFrame will be used for filtering and for merging the names

try:
    df_allotment_names = pd.read_csv(
        allotment_names_file,
        header=0,
        names=['AllotmentAreaCode', 'AllotmentName']
    )

    # Ensure codes are strings and remove any leading/trailing whitespace
    df_allotment_names['AllotmentAreaCode'] = (
        df_allotment_names['AllotmentAreaCode']
        .astype(str)
        .str.strip()
    )

    # Create a set of unique codes for very fast lookup during filtering
    wanted_allotment_codes_set = set(
        df_allotment_names['AllotmentAreaCode']
    )

    print(
        f"Loaded {len(df_allotment_names)} allotment area names."
    )

    print(
        f"Prepared {len(wanted_allotment_codes_set)} "
        "unique codes for filtering."
    )

except FileNotFoundError:
    print(
        f"Error: The file '{allotment_names_file}' was not found. "
        "Please make sure it's in the correct directory."
    )
    exit()

except Exception as e:
    print(
        f"An error occurred loading allotment names: {e}"
    )
    exit()


# --- Step 2: Process the Large Data File Line by Line ---

# This approach is memory-efficient for large files as it avoids
# loading everything at once.
# It reads in chunks and processes them.

chunk_size = 100000
filtered_rows = []
total_rows_processed = 0

print(
    f"Starting to process the large data file: {large_data_file}"
)


try:

    # Use iterator=True to read in chunks
    for chunk in pd.read_csv(
        large_data_file,
        header=None,
        names=[
            'PropertyDiagramNumber',
            'UniqueIdNumber'
        ],
        sep=',',
        quotechar='"',
        dtype={
            'PropertyDiagramNumber': str,
            'UniqueIdNumber': str
        },
        chunksize=chunk_size
    ):

        total_rows_processed += len(chunk)

        # Extract the 8-digit allotment code from the
        # UniqueIdNumber (second column)

        chunk['AllotmentAreaCode'] = (
            chunk['UniqueIdNumber'].str[:8]
        )

        # Filter the chunk based on the wanted allotment codes

        filtered_chunk = chunk[
            chunk['AllotmentAreaCode'].isin(
                wanted_allotment_codes_set
            )
        ]

        # Store the filtered rows

        if not filtered_chunk.empty:
            filtered_rows.append(filtered_chunk)

        if total_rows_processed % 1000000 == 0:
            print(
                f"Processed "
                f"{total_rows_processed / 1000000:.0f} million rows..."
            )


    # Concatenate all filtered chunks into a single DataFrame

    if filtered_rows:

        df_filtered_data = pd.concat(filtered_rows)

        print(
            f"Finished initial filtering. "
            f"Found {len(df_filtered_data)} matching rows."
        )

    else:

        df_filtered_data = pd.DataFrame(
            columns=[
                'PropertyDiagramNumber',
                'UniqueIdNumber',
                'AllotmentAreaCode'
            ]
        )

        print(
            "No matching rows found in the large data file."
        )


except FileNotFoundError:

    print(
        f"Error: The large data file '{large_data_file}' "
        "was not found. "
        "Please ensure the path is correct."
    )
    exit()

except Exception as e:

    print(
        f"An error occurred during processing "
        f"the large data file: {e}"
    )
    exit()


# --- Step 3: Merge with Allotment Names ---

if not df_filtered_data.empty:

    df_final_output = pd.merge(
        df_filtered_data,
        df_allotment_names[
            [
                'AllotmentAreaCode',
                'AllotmentName'
            ]
        ],
        on='AllotmentAreaCode',
        how='left'
    )

    # Select and reorder final columns:
    # Property Diagram, Unique ID, Allotment Name

    df_final_output = df_final_output[
        [
            'PropertyDiagramNumber',
            'UniqueIdNumber',
            'AllotmentName'
        ]
    ]

    # --- Step 4: Save the Final Output ---

    df_final_output.to_csv(
        output_filtered_file,
        index=False,
        quoting=csv.QUOTE_MINIMAL
    )

    print(
        f"Final data saved to: {output_filtered_file}"
    )

else:

    print(
        "No data to save after filtering."
    )


print("Process complete.")
