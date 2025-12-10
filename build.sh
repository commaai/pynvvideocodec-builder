#!/bin/bash
set -e

# Check if source path argument is provided
if [ $# -eq 0 ]; then
    echo "Usage: $0 <source-path>"
    echo "  source-path: Path to the PyNvVideoCodec zip file"
    exit 1
fi

# Make sure the source path exists and is a zip file
SOURCE_PATH="$1"
if [ ! -f "$SOURCE_PATH" ]; then
    echo "Error: Source file '$SOURCE_PATH' not found"
    exit 1
fi
if [[ ! "$SOURCE_PATH" =~ \.zip$ ]]; then
    echo "Error: Source file must be a .zip file"
    exit 1
fi

echo "Building PyNvVideoCodec from: $SOURCE_PATH"
echo "Extracting source archive..."
unzip -q "$SOURCE_PATH"

EXTRACTED_DIR=$(find . -maxdepth 1 -type d -name "PyNvVideoCodec_*" | head -n1)
if [ -z "$EXTRACTED_DIR" ]; then
    echo "Error: Could not find extracted PyNvVideoCodec directory"
    exit 1
fi

# Apply the patch
echo "Applying patch..."
chmod +rw -R "$EXTRACTED_DIR"
cd "$EXTRACTED_DIR"
patch -p1 < ../patch

# Run pip wheel to build the package
echo "Building wheel..."
mkdir -p ../build
pip wheel . --wheel-dir ../build --no-deps
echo "Build completed successfully!"
echo "Wheel file created in: build/"
