#!/bin/bash
# Script to convert xcarchive to ipa

# Usage: ./create_ipa.sh path/to/your.xcarchive output.ipa

XCARCHIVE_PATH="$1"
OUTPUT_IPA="$2"

if [ -z "$XCARCHIVE_PATH" ] || [ -z "$OUTPUT_IPA" ]; then
    echo "Usage: ./create_ipa.sh path/to/your.xcarchive output.ipa"
    exit 1
fi

# Create Payload directory
mkdir -p Payload

# Copy the .app bundle
cp -r "$XCARCHIVE_PATH/Products/Applications/Runner.app" Payload/

# Create the ipa (which is just a zip file)
zip -r "$OUTPUT_IPA" Payload

# Clean up
rm -rf Payload

echo "Created $OUTPUT_IPA"
