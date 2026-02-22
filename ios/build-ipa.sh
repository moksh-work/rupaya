#!/bin/bash
# iOS App IPA Builder - Ad Hoc Distribution
# Generates an installable IPA file without App Store upload

set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
ARCHIVE_PATH="$BUILD_DIR/RUPAYA.xcarchive"
EXPORT_DIR="$BUILD_DIR/IPA"
EXPORT_PLIST="$PROJECT_DIR/ExportOptions.plist"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}   RUPAYA iOS IPA Builder${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check for Apple ID and Team ID
echo -e "${YELLOW}Step 0: Checking Xcode Configuration${NC}"

# Try to get team ID from Xcode project
TEAM_ID=$(grep -r "DEVELOPMENT_TEAM" "$PROJECT_DIR/RUPAYA.xcodeproj/project.pbxproj" | head -1 | sed 's/.*DEVELOPMENT_TEAM = //;s/;.*//' | tr -d ' ')

if [ -z "$TEAM_ID" ]; then
  echo -e "${RED}⚠ No development team found in project.${NC}"
  echo -e "${YELLOW}Please sign in to Xcode:${NC}"
  echo "  1. Open Xcode"
  echo "  2. Xcode menu → Settings → Accounts"
  echo "  3. Click '+' to add your Apple ID"
  echo "  4. Then select RUPAYA project → Signing & Capabilities"
  echo "  5. Select your team from 'Team' dropdown"
  echo ""
  read -p "Press Enter after you've set your team in Xcode, then run this script again..."
  exit 1
fi

echo -e "${GREEN}✓${NC} Development Team: $TEAM_ID"

# Create build directories
echo -e "${YELLOW}Setting up build directories...${NC}"
mkdir -p "$BUILD_DIR"
mkdir -p "$EXPORT_DIR"

# Create ExportOptions.plist if it doesn't exist
if [ ! -f "$EXPORT_PLIST" ]; then
  echo -e "${YELLOW}Creating ExportOptions.plist...${NC}"
  cat > "$EXPORT_PLIST" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>ad-hoc</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>teamID</key>
    <string>$TEAM_ID</string>
    <key>provisioningProfiles</key>
    <dict/>
</dict>
</plist>
EOF
  echo -e "${GREEN}✓${NC} ExportOptions.plist created with Team ID: $TEAM_ID"
fi

# Step 1: Build Archive
echo ""
echo -e "${YELLOW}Step 1: Building Archive${NC}"
echo "This may take a few minutes..."

xcodebuild \
  -workspace "$PROJECT_DIR/RUPAYA.xcworkspace" \
  -scheme RUPAYA \
  -configuration Release \
  -derivedDataPath "$BUILD_DIR/derived" \
  -archivePath "$ARCHIVE_PATH" \
  -allowProvisioningUpdates \
  archive

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓${NC} Archive created successfully"
else
  echo -e "${RED}✗${NC} Archive creation failed"
  exit 1
fi

# Step 2: Export IPA
echo ""
echo -e "${YELLOW}Step 2: Exporting IPA File${NC}"

xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -exportPath "$EXPORT_DIR"

if [ $? -eq 0 ]; then
  echo -e "${GREEN}✓${NC} IPA exported successfully"
else
  echo -e "${RED}✗${NC} IPA export failed"
  exit 1
fi

# Find the generated IPA
IPA_FILE=$(find "$EXPORT_DIR" -name "*.ipa" | head -1)

if [ -z "$IPA_FILE" ]; then
  echo -e "${RED}✗${NC} IPA file not found"
  exit 1
fi

# Display results
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Build Complete!${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "${GREEN}IPA File Location:${NC}"
echo "  $IPA_FILE"
echo ""
echo -e "${GREEN}File Size: $(du -h "$IPA_FILE" | cut -f1)${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Connect your iPad/iPhone via USB"
echo "2. Use Apple Configurator 2, or"
echo "3. Upload to Diawi.com for easy sharing:"
echo "   https://www.diawi.com"
echo ""
echo -e "${YELLOW}To install on connected device:${NC}"
echo "   1. Open Xcode Window → Devices and Simulators"
echo "   2. Select your device"
echo "   3. Drag and drop the IPA file"
echo ""
echo -e "${YELLOW}To share with others:${NC}"
echo "   1. Visit https://www.diawi.com"
echo "   2. Upload: $IPA_FILE"
echo "   3. Share the download link"
echo ""
