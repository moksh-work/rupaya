#!/bin/bash
# Create iOS Xcode project using xcodebuild

TEMPLATE_DIR="/Applications/Xcode.app/Contents/Developer/Library/Xcode/Templates/Project Templates/iOS/Application/App.xctemplate"

if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "Xcode templates not found. Using manual creation..."
  
  # Create using xcodebuild directly
  xcodebuild -create-xcodeproj RUPAYA.xcodeproj
else
  echo "Creating from template..."
fi
