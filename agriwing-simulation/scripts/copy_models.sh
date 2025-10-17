#!/bin/bash

# Script to copy agriwing model to Tools/simulation/gz/models
# Usage: ./copy_models.sh

set -e  # Exit on error

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script's directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"

# Define source and destination paths
SOURCE_DIR="$PROJECT_ROOT/agriwing-simulation/custom_models/agriwing"
DEST_DIR="$PROJECT_ROOT/Tools/simulation/gz/models"

echo -e "${YELLOW}Copying agriwing model...${NC}"
echo "Source: $SOURCE_DIR"
echo "Destination: $DEST_DIR"

# Check if source directory exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}Error: Source directory does not exist: $SOURCE_DIR${NC}"
    exit 1
fi

# Check if destination directory exists, create if not
if [ ! -d "$DEST_DIR" ]; then
    echo -e "${YELLOW}Destination directory does not exist. Creating: $DEST_DIR${NC}"
    mkdir -p "$DEST_DIR"
fi

# Check if agriwing already exists in destination
if [ -d "$DEST_DIR/agriwing" ]; then
    echo -e "${YELLOW}Warning: agriwing directory already exists in destination.${NC}"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${RED}Operation cancelled.${NC}"
        exit 1
    fi
    echo -e "${YELLOW}Removing existing directory...${NC}"
    rm -rf "$DEST_DIR/agriwing"
fi

# Copy the directory
echo -e "${YELLOW}Copying directory...${NC}"
cp -r "$SOURCE_DIR" "$DEST_DIR/"

# Verify the copy was successful
if [ -d "$DEST_DIR/agriwing" ]; then
    echo -e "${GREEN}Success! agriwing model copied to: $DEST_DIR/agriwing${NC}"

    # Verify source still exists
    if [ -d "$SOURCE_DIR" ]; then
        echo -e "${GREEN}Source directory preserved at: $SOURCE_DIR${NC}"
    fi
else
    echo -e "${RED}Error: Copy operation may have failed. Please check manually.${NC}"
    exit 1
fi

echo -e "${GREEN}Done!${NC}"
