#!/bin/bash
# Install RUPAYA app on iPad using Apple Configurator 2

BUILT_APP="/Users/rsingh/Documents/Projects/rupaya/ios/build/derived/Build/Products/Debug-iphoneos/RUPAYA.app"

echo "=========================================="
echo "  RUPAYA Installation Instructions"
echo "=========================================="
echo ""
echo "Built app location:"
echo "  $BUILT_APP"
echo ""
echo "Next steps:"
echo "1. Make sure your iPad is connected via USB"
echo "2. Open Apple Configurator 2 (or install from App Store)"
echo "3. You should see your iPad listed on the left sidebar"
echo "4. Click the '+' button at the top"
echo "5. Select 'Add' → 'Apps'"
echo "6. Browse to: $BUILT_APP"
echo "7. Select the RUPAYA.app and click Open"
echo "8. Click 'Next' and then 'Install'"
echo ""
echo "Opening Apple Configurator 2..."
open -a "Apple Configurator 2"
