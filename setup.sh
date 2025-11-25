#!/bin/bash

# Setup script for Industrial Configurator iOS App
# This script should be run on macOS with Xcode and XcodeGen installed

set -e

echo "Industrial Configurator - Project Setup"
echo "======================================="

# Check for XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo "XcodeGen not found. Installing via Homebrew..."
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo "Error: Homebrew not found. Please install Homebrew first:"
        echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
fi

# Generate Xcode project
echo "Generating Xcode project..."
xcodegen generate

echo ""
echo "Setup complete! You can now open IndustrialConfigurator.xcodeproj in Xcode."
echo ""
echo "To build from command line:"
echo "  xcodebuild -scheme IndustrialConfigurator -destination 'generic/platform=iOS' clean build"
