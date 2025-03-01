#!/bin/bash

# Exit on error
set -e

echo "🧹 Starting project cleanup..."

# Run Flutter clean
echo "🗑️  Running Flutter clean..."
flutter clean

# Remove pub cache files
echo "🗑️  Cleaning pub cache..."
flutter pub cache clean

# Remove iOS build artifacts
echo "🗑️  Cleaning iOS build artifacts..."
rm -rf ios/Pods
rm -rf ios/.symlinks
rm -rf ios/build
rm -rf ios/Runner.xcworkspace/xcuserdata
rm -rf ios/Flutter/ephemeral
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/Generated.xcconfig
rm -rf ios/Flutter/flutter_export_environment.sh
rm -rf ios/DerivedData
rm -rf ios/.generated

# Remove Android build artifacts
echo "🗑️  Cleaning Android build artifacts..."
rm -rf android/.gradle
rm -rf android/captures
rm -rf android/app/.cxx
rm -rf android/app/build

# Remove macOS build artifacts
echo "🗑️  Cleaning macOS build artifacts..."
rm -rf macos/Flutter/ephemeral
rm -rf macos/Flutter/GeneratedPluginRegistrant.*
rm -rf macos/Pods

# Remove other temp files
echo "🗑️  Removing temporary files..."
find . -name "*.log" -type f -delete
find . -name ".DS_Store" -type f -delete
find . -name "*.iml" -type f -delete
find . -name "*.bak" -type f -delete
find . -name "*.tmp" -type f -delete
find . -name "*.temp" -type f -delete

# Get new dependencies
echo "🔄 Getting dependencies..."
flutter pub get

echo "✅ Cleanup complete!" 