# Rupaya App Icon Generation Guide

This guide explains how to generate all required iOS and Android app icon PNGs from a single SVG source using the provided script.

## Prerequisites
- macOS or Linux
- [ImageMagick](https://imagemagick.org) and [librsvg](https://wiki.gnome.org/Projects/LibRsvg) (for `rsvg-convert`)
- Install via Homebrew:
  ```sh
  brew install imagemagick librsvg
  ```

## Usage
1. Place your base icon SVG (e.g., `AppIcon.svg`) in a known location.
2. Run the script:
   ```sh
   cd deployment/scripts
   chmod +x generate_app_icons.sh
   ./generate_app_icons.sh <path/to/AppIcon.svg> <output_dir>
   ```
   Example:
   ```sh
   ./generate_app_icons.sh ../../ios/RUPAYA/AppIcon.svg ./output_icons
   ```
3. The script will create:
   - `output_dir/ios/` with all iOS icon PNGs (for Assets.xcassets)
   - `output_dir/android/` with all Android mipmap PNGs (for res/mipmap-*)

## iOS Icon Sizes Generated
- 20x20, 29x29, 40x40, 60x60, 76x76, 83.5x83.5, 1024x1024 (various @1x, @2x, @3x)

## Android Icon Sizes Generated
- mdpi (48x48), hdpi (72x72), xhdpi (96x96), xxhdpi (144x144), xxxhdpi (192x192)

## Next Steps
- Copy the generated PNGs to your Xcode Assets.xcassets (iOS) and `android/app/src/main/res/mipmap-*` (Android) folders.
- Commit the new icons to your repo.

---

For any issues, see the script comments or contact the DevOps team.
