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
rm -rf ../build/
pip wheel . --wheel-dir ../build --no-deps
echo "Build completed successfully!"

# Run auditwheel to bundle in libcudart
echo "Repairing wheel..."
cd ..
auditwheel repair --exclude libavutil.so --exclude libavutil.so. --exclude libavcodec.so --exclude libavformat.so --exclude libavfilter.so --exclude libavdevice.so --exclude libswresample.so --exclude libswscale.so --exclude 'libcuda.so*' ./build/*.whl -w ./wheelhouse/
echo "Wheel repaired successfully!"
echo "Wheel file created in: wheelhouse/"
