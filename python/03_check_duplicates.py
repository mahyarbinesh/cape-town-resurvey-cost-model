import pandas as pd

# Define the input file path
input_file = 'CT_Allotments.csv'

try:
    # Load the CSV file
    df = pd.read_csv(input_file)

    print("Columns in the CSV file:")
    print(df.columns.tolist())

    # Check for duplicates in TOWN_CODE
    duplicate_codes = df[
        df.duplicated(
            subset=['TOWN_CODE'],
            keep=False
        )
    ]

    if not duplicate_codes.empty:

        print(
            f"\nFound {len(duplicate_codes)} rows "
            "with duplicate TOWN_CODEs:"
        )

        print(
            duplicate_codes.sort_values(
                'TOWN_CODE'
            ).to_string(index=False)
        )

    else:

        print(
            "\nNo duplicate TOWN_CODEs found."
        )

except FileNotFoundError:

    print(
        f"Error: The file '{input_file}' was not found. "
        "Please make sure it's in the same directory as the script, "
        "or provide the full path."
    )

except Exception as e:

    print(f"An error occurred: {e}")
