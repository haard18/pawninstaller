#!/bin/bash

# WhiteBeard Pawn Plugin Installer Build Script (WiX v4)

echo "========================================"
echo "WhiteBeard Pawn Plugin Installer Build"
echo "========================================"
echo ""

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT_DIR="$PROJECT_DIR/bin/Release"

# Step 1: Build Custom Actions
echo "Step 1: Building Custom Actions..."
cd "$PROJECT_DIR/CustomActions"
dotnet restore
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to restore CustomActions project"
    exit 1
fi

dotnet build -c Release
if [ $? -ne 0 ]; then
    echo "ERROR: Failed to build CustomActions project"
    exit 1
fi
cd "$PROJECT_DIR"

echo ""
echo "Step 2: Building MSI with WiX v4..."

# Check if wix command is available
if ! command -v wix &> /dev/null; then
    echo "ERROR: WiX v4 not found!"
    echo ""
    echo "Please install WiX v4 using:"
    echo "  dotnet tool install --global wix"
    echo ""
    echo "Or update if already installed:"
    echo "  dotnet tool update --global wix"
    echo ""
    exit 1
fi

# Build the MSI
mkdir -p "$OUT_DIR"
wix build -o "$OUT_DIR/WhiteBeardPawnPlugin.msi" WhiteBeardPawnPlugin.wixproj -pdbtype none -arch x64

if [ $? -ne 0 ]; then
    echo "ERROR: WiX build failed"
    exit 1
fi

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "MSI created at: $OUT_DIR/WhiteBeardPawnPlugin.msi"
echo "========================================"
