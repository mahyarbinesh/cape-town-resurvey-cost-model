import pandas as pd


# Define the input file path
input_allotments_file = 'CT_Allotments.csv'

# Define the output file path for the plain text codes
output_codes_for_awk = 'unique_wanted_allotment_codes.txt'


try:

    # Load the allotment areas file
    # We specify 'header=0' because we know the first row is a header
    df_allotments = pd.read_csv(input_allotments_file)

    # Extract only the 'TOWN_CODE' column
    allotment_codes = df_allotments['TOWN_CODE']

    # Ensure codes are unique
    unique_codes = allotment_codes.drop_duplicates()

    # Save these unique codes to a plain text file,
    # one per line, without the header/index
    unique_codes.to_csv(
        output_codes_for_awk,
        index=False,
        header=False
    )

    print(
        f"Successfully extracted "
        f"{len(unique_codes)} unique allotment codes."
    )

    print(
        f"Codes saved to: {output_codes_for_awk}"
    )


except FileNotFoundError:

    print(
        f"Error: The file '{input_allotments_file}' was not found. "
        "Please make sure it's in the same directory as the script, "
        "or provide the full path."
    )


except Exception as e:

    print(f"An error occurred: {e}")
