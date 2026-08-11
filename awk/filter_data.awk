BEGIN {

    # Load wanted 8-digit allotment codes into a hash map for fast lookup

    while (getline < "unique_wanted_allotment_codes.txt" > 0) {

        wanted_codes[trim($1)] = 1

    }

}

{

    # Extract the second field (UniqueIdNumber) and remove quotes

    # $2 is the unique ID (e.g., "C01600340003149200000")

    unique_id_full = substr($2, 2, length($2) - 2)

    # Extract the first 8 digits of the UniqueIdNumber (the allotment prefix)

    allotment_prefix = substr(unique_id_full, 1, 8)

    # Check if this prefix is in our list of wanted codes

    if (allotment_prefix in wanted_codes) {

        # Print the original two fields AND the extracted 8-digit prefix

        print $1 "," $2 ",\"" allotment_prefix "\""

    }

}

# trim function to remove leading/trailing whitespace

function trim(s) {

    sub(/^[ \t\r\n]+/, "", s)

    sub(/[ \t\r\n]+$/, "", s)

    return s

}
