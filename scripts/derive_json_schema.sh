#!/bin/bash
VERSION="0.1.4"

# Check if input and output are provided
# Usage: ./run_derive_json_schema.sh <input_file> <output_file>
if [ $# -ne 2 ]; then
    exit 1
fi

input="$1"
output="$2"

# Run the command pipeline
cat "$input" | wasmer run moonbitlang/derive_json_schema@$VERSION | moonfmt - > "$output"

# Check if the command was successful
if [ $? -ne 0 ]; then
    exit 1
fi


