#!/bin/bash
# iOS Project Setup Script

set -e

cd "$(dirname "$0")"

echo "Setting up iOS Xcode project..."

# Create Xcode project using xcodeproj gem or manually
# For now, we'll create a minimal project structure

PROJECT_NAME="RUPAYA"
BUNDLE_ID="com.rupaya.app"

# Create project.pbxproj structure
mkdir -p "$PROJECT_NAME.xcodeproj"

cat > "$PROJECT_NAME.xcodeproj/project.pbxproj" << 'EOF'
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 56;
	objects = {
		mainGroup = {
			isa = PBXGroup;
			children = (
			);
			sourceTree = "<group>";
		};
		productRefGroup = {
			isa = PBXGroup;
			children = (
			);
			name = Products;
			sourceTree = "<group>";
		};
	};
	rootObject = {
		isa = PBXProject;
		attributes = {
			BuildIndependentTargetsInParallel = 1;
			LastSwiftUpdateCheck = 1500;
			LastUpgradeCheck = 1500;
		};
		buildConfigurationList = {
		};
		compatibilityVersion = "Xcode 14.0";
		developmentRegion = en;
		hasScannedForEncodings = 0;
		knownRegions = (
			en,
			Base,
		);
		mainGroup = mainGroup;
		productRefGroup = productRefGroup;
		projectDirPath = "";
		projectRoot = "";
		targets = (
		);
	};
}
EOF

echo "✓ Xcode project structure created"
echo ""
echo "Next steps:"
echo "1. Open Xcode"
echo "2. File → Open → Select ios/RUPAYA.xcodeproj"
echo "3. Add existing Swift files from RUPAYA/ folder"
echo "4. Configure signing & capabilities"
echo "5. Run: pod install"
echo "6. Open RUPAYA.xcworkspace (not .xcodeproj)"
