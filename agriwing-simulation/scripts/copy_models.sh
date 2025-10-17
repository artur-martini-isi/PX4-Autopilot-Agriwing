#!/bin/bash

# Script to copy agriwing models and worlds to Tools/simulation/gz
# Usage: ./copy_agriwing_model.sh

set -e  # Exit on error

# Define colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get the script's directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null || echo "$SCRIPT_DIR")"

# Define source and destination paths for models
MODELS_SOURCE_DIR="$PROJECT_ROOT/agriwing-simulation/custom_models/models"
MODELS_DEST_DIR="$PROJECT_ROOT/Tools/simulation/gz/models/agriwing"

# Define source and destination paths for worlds
WORLDS_SOURCE_FILE="$PROJECT_ROOT/agriwing-simulation/custom_models/worlds/agriwing.sdf"
WORLDS_DEST_DIR="$PROJECT_ROOT/Tools/simulation/gz/worlds"

echo -e "${YELLOW}========================================${NC}"
echo -e "${YELLOW}Copying agriwing simulation files...${NC}"
echo -e "${YELLOW}========================================${NC}"

# =====================
# COPY MODELS
# =====================
echo -e "\n${YELLOW}[1/2] Processing models...${NC}"
echo "Source: $MODELS_SOURCE_DIR"
echo "Destination: $MODELS_DEST_DIR"

# Check if source directory exists
if [ ! -d "$MODELS_SOURCE_DIR" ]; then
    echo -e "${RED}Error: Models source directory does not exist: $MODELS_SOURCE_DIR${NC}"
    exit 1
fi

# Check if destination directory exists, create if not
if [ ! -d "$MODELS_DEST_DIR" ]; then
    echo -e "${YELLOW}Models destination directory does not exist. Creating: $MODELS_DEST_DIR${NC}"
    mkdir -p "$MODELS_DEST_DIR"
fi

# Copy all models from source to destination
echo -e "${YELLOW}Copying model files...${NC}"
for model in "$MODELS_SOURCE_DIR"/*; do
    if [ -e "$model" ]; then
        model_name=$(basename "$model")

        # Check if model already exists in destination
        if [ -e "$MODELS_DEST_DIR/$model_name" ]; then
            echo -e "${YELLOW}Warning: $model_name already exists in destination.${NC}"
            read -p "Do you want to overwrite it? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                echo -e "${YELLOW}Skipping $model_name${NC}"
                continue
            fi
            echo -e "${YELLOW}Removing existing $model_name...${NC}"
            rm -rf "$MODELS_DEST_DIR/$model_name"
        fi

        cp -r "$model" "$MODELS_DEST_DIR/"
        echo -e "${GREEN}✓ Copied: $model_name${NC}"
    fi
done

# =====================
# COPY WORLD FILE
# =====================
echo -e "\n${YELLOW}[2/2] Processing world file...${NC}"
echo "Source: $WORLDS_SOURCE_FILE"
echo "Destination: $WORLDS_DEST_DIR"

# Check if source file exists
if [ ! -f "$WORLDS_SOURCE_FILE" ]; then
    echo -e "${RED}Error: World file does not exist: $WORLDS_SOURCE_FILE${NC}"
    exit 1
fi

# Check if destination directory exists, create if not
if [ ! -d "$WORLDS_DEST_DIR" ]; then
    echo -e "${YELLOW}Worlds destination directory does not exist. Creating: $WORLDS_DEST_DIR${NC}"
    mkdir -p "$WORLDS_DEST_DIR"
fi

# Check if world file already exists in destination
if [ -f "$WORLDS_DEST_DIR/agriwing.sdf" ]; then
    echo -e "${YELLOW}Warning: agriwing.sdf already exists in destination.${NC}"
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Skipping agriwing.sdf${NC}"
    else
        cp "$WORLDS_SOURCE_FILE" "$WORLDS_DEST_DIR/"
        echo -e "${GREEN}✓ Copied: agriwing.sdf${NC}"
    fi
else
    cp "$WORLDS_SOURCE_FILE" "$WORLDS_DEST_DIR/"
    echo -e "${GREEN}✓ Copied: agriwing.sdf${NC}"
fi

# =====================
# VERIFICATION
# =====================
echo -e "\n${YELLOW}========================================${NC}"
echo -e "${YELLOW}Verifying copy operations...${NC}"
echo -e "${YELLOW}========================================${NC}"

# Verify models
models_count=$(find "$MODELS_DEST_DIR" -maxdepth 1 -type d -o -type f | grep -v "^$MODELS_DEST_DIR$" | wc -l)
echo -e "${GREEN}Models directory contains: $models_count items${NC}"

# Verify world file
if [ -f "$WORLDS_DEST_DIR/agriwing.sdf" ]; then
    echo -e "${GREEN}World file exists: agriwing.sdf${NC}"
else
    echo -e "${RED}Warning: World file not found in destination${NC}"
fi

# Verify source directories still exist
if [ -d "$MODELS_SOURCE_DIR" ]; then
    echo -e "${GREEN}Source models directory preserved${NC}"
fi
if [ -f "$WORLDS_SOURCE_FILE" ]; then
    echo -e "${GREEN}Source world file preserved${NC}"
fi

echo -e "\n${GREEN}========================================${NC}"
echo -e "${GREEN}Done! All files copied successfully.${NC}"
echo -e "${GREEN}========================================${NC}"
