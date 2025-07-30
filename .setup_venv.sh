#!/bin/bash

# Script to create a Python venv in memory and dump it to a squashfs file

set -e

MODULE_DIR="$PWD/PL-GRID-SETUP"
USERNAME=$(grep -oP '"username"\s*:\s*"\K[^"]+' "$MODULE_DIR/config.json")

# Check MEMFS
if [ -z "$MEMFS" ]; then
    echo "Error: MEMFS is not set. Please set MEMFS before running the script."
    exit 1
fi

echo "MEMFS is set to: $MEMFS"

# Define paths
VENV_PATH="$MEMFS/envs/$USERNAME"
SQUASHFS_PATH="$MEMFS/$USERNAME.sqsh"

# Unmount if already mounted
if mountpoint -q "$VENV_PATH"; then
    echo "Unmounting existing squashfs mount at $VENV_PATH..."
    fusermount -u "$VENV_PATH" || { echo "Error: Failed to unmount squashfs."; exit 1; }
fi

# Clean up any previous venv or squashfs image
echo "Cleaning up previous environment..."
rm -rf "$VENV_PATH" "$SQUASHFS_PATH"

# Create new venv
echo "Creating Python virtual environment..."
python3 -m venv "$VENV_PATH"

# Activate and install requirements
source "$VENV_PATH/bin/activate"

if [ -f requirements.txt ]; then
    echo "Installing packages from requirements.txt..."
    pip install --upgrade pip
    pip install -r requirements.txt
else
    echo "Warning: environment.txt not found. Empty venv will be created."
fi

deactivate

# Create squashfs
echo "Packing venv to squashfs..."
mksquashfs "$VENV_PATH" "$SQUASHFS_PATH" -comp lz4 -Xhc

# Clean up uncompressed venv
echo "Cleaning up uncompressed venv..."
rm -rf "$VENV_PATH"

# Move squashfs to HOME
echo "Moving squashfs to $HOME..."
mv "$SQUASHFS_PATH" "$HOME/$USERNAME.sqsh"

echo "✅ Done!"
