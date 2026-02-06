#!/bin/bash
# Script to generate iOS and Android app icons from a base SVG using ImageMagick and rsvg-convert
# Requirements: brew install imagemagick librsvg
# Usage: ./generate_app_icons.sh <input_svg> <output_dir>

set -e

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <input_svg> <output_dir>"
  exit 1
fi

INPUT_SVG="$1"
OUTPUT_DIR="$2"

# iOS icon sizes (pt): 20, 29, 40, 60, 76, 83.5, 1024 (various @1x, @2x, @3x)
declare -A IOS_SIZES=(
  [Icon-App-20x20@1x]=20
  [Icon-App-20x20@2x]=40
  [Icon-App-20x20@3x]=60
  [Icon-App-29x29@1x]=29
  [Icon-App-29x29@2x]=58
  [Icon-App-29x29@3x]=87
  [Icon-App-40x40@1x]=40
  [Icon-App-40x40@2x]=80
  [Icon-App-40x40@3x]=120
  [Icon-App-60x60@2x]=120
  [Icon-App-60x60@3x]=180
  [Icon-App-76x76@1x]=76
  [Icon-App-76x76@2x]=152
  [Icon-App-83.5x83.5@2x]=167
  [Icon-App-1024x1024@1x]=1024
)

mkdir -p "$OUTPUT_DIR/ios"
echo "Generating iOS icons..."
for name in "${!IOS_SIZES[@]}"; do
  size=${IOS_SIZES[$name]}
  rsvg-convert -w $size -h $size "$INPUT_SVG" -o "$OUTPUT_DIR/ios/$name.png"
done

echo "iOS icons generated in $OUTPUT_DIR/ios"

# Android icon sizes (px): mdpi=48, hdpi=72, xhdpi=96, xxhdpi=144, xxxhdpi=192
declare -A ANDROID_SIZES=(
  [mipmap-mdpi]=48
  [mipmap-hdpi]=72
  [mipmap-xhdpi]=96
  [mipmap-xxhdpi]=144
  [mipmap-xxxhdpi]=192
)

for dir in "${!ANDROID_SIZES[@]}"; do
  size=${ANDROID_SIZES[$dir]}
  mkdir -p "$OUTPUT_DIR/android/$dir"
  rsvg-convert -w $size -h $size "$INPUT_SVG" -o "$OUTPUT_DIR/android/$dir/ic_launcher.png"
done

echo "Android icons generated in $OUTPUT_DIR/android"

echo "All icons generated successfully."
