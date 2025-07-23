#!/bin/bash

# Script to create a Conda virtual environment in memory and dump it to a single file

# Load the miniconda3 module for Conda functionality
module load miniconda3 || { echo "Error: Failed to load miniconda3 module."; exit 1; }

echo "Miniconda3 module loaded successfully."

USERNAME=$(grep -oP '"username"\s*:\s*"\K[^"]+' config.json)

# Check if MEMFS variable is set
if [ -z "$MEMFS" ]; then
    echo "Error: MEMFS is not set. Please set MEMFS before running the script."
    exit 1
fi

echo "MEMFS is set to: $MEMFS"

# Define paths
ENV_PATH="$MEMFS/envs/$USERNAME"
SQUASHFS_PATH="$MEMFS/$USERNAME.sqsh"

# Unmount squashfs if it is already mounted
if mountpoint -q "$ENV_PATH"; then
    echo "Unmounting existing squashfs mount at $ENV_PATH..."
    fusermount -u "$ENV_PATH" || { echo "Error: Failed to unmount squashfs."; exit 1; }
    echo "Squashfs unmounted successfully."
fi

# Deactivate Conda environment if active
if [[ -n "$CONDA_PREFIX" ]]; then
    echo "Deactivating Conda environment..."
    conda deactivate
fi

# Clean up any existing Conda environment directories in MEMFS
echo "Cleaning up existing virtual environment directories in $MEMFS..."
rm -rf "$MEMFS/.conda" "$ENV_PATH" "$SQUASHFS_PATH"

# Set up Conda directories in MEMFS for performance
export CONDA_PKGS_DIRS=$MEMFS/.conda/pkgs
export CONDA_ENVS_DIRS=$MEMFS/.conda/envs
export CONDA_TEMP=$MEMFS/.conda/tmp

# Create Conda environment
echo "Creating Conda environment..."
conda env create --prefix "$ENV_PATH" --file environment.yml --yes || { echo "Error: Failed to create Conda environment."; exit 1; }

# Compress Conda environment into a SquashFS image
echo "Creating SquashFS image..."
mksquashfs "$ENV_PATH" "$SQUASHFS_PATH" -comp lz4 -Xhc || { echo "Error: Failed to create SquashFS image."; exit 1; }


echo "SquashFS image created successfully at $SQUASHFS_PATH."

# Clean up the Conda environment directory
echo "Cleaning up Conda environment directory..."
rm -rf "$ENV_PATH" || { echo "Error: Failed to clean up Conda environment directory."; exit 1; }        

# Moving squashfs image to HOME directory
echo "Moving SquashFS image to HOME directory..."
mv "$SQUASHFS_PATH" "$HOME/$USERNAME.sqsh" || { echo "Error: Failed to move SquashFS image to HOME directory."; exit 1; }

echo "Done!"
 