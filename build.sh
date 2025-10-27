#!/bin/bash

# WhiteBeard Pawn Plugin Installer Build Script (Cross-platform alternative)
# Note: This requires WiX to be installed and accessible

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
echo "Step 2: Compiling WiX source files..."
# Note: On non-Windows, you would use wixl or similar tools
# This script assumes WiX is in PATH
candle -ext WixUIExtension -ext WixUtilExtension -o "obj/Release/" Product.wxs LicenseVerificationDialog.wxs MT5DetectionDialog.wxs UI/InstallDialogs.wxs
if [ $? -ne 0 ]; then
    echo "ERROR: WiX compilation failed"
    exit 1
fi

echo ""
echo "Step 3: Linking MSI package..."
mkdir -p "$OUT_DIR"
light -ext WixUIExtension -ext WixUtilExtension -o "$OUT_DIR/WhiteBeardPawnPlugin.msi" -cultures:en-us obj/Release/*.wixobj
if [ $? -ne 0 ]; then
    echo "ERROR: WiX linking failed"
    exit 1
fi

echo ""
echo "========================================"
echo "Build completed successfully!"
echo "MSI created at: $OUT_DIR/WhiteBeardPawnPlugin.msi"
echo "========================================"
