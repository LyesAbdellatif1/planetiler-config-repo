#!/bin/bash

# Download OpenMapTiles Fonts for text rendering
# These fonts are required for proper text display in TileServer GL

set -e

echo "=== OpenMapTiles Fonts Download ==="
echo "Downloading fonts for TileServer GL..."

# Create fonts directory
mkdir -p data/fonts

cd data/fonts

# Download font package from OpenMapTiles
# This includes fonts like "Open Sans", "Noto Sans", etc.
FONTS_URL="https://github.com/openmaptiles/fonts/releases/download/v1.0/fonts.zip"

if [ ! -f "fonts.zip" ]; then
    echo "Downloading fonts package (this may take a few minutes)..."
    curl -L -o fonts.zip "$FONTS_URL" || {
        echo "⚠️  Warning: Could not download fonts from GitHub"
        echo "TileServer GL will use system fonts as fallback"
        cd ../..
        exit 0
    }
    
    echo "✓ Downloaded fonts.zip"
    
    # Extract fonts
    echo "Extracting fonts..."
    unzip -q fonts.zip
    rm fonts.zip
    echo "✓ Fonts extracted"
else
    echo "✓ Fonts already exist, skipping download"
fi

cd ../..

# Count downloaded fonts
FONT_COUNT=$(find data/fonts -name "*.pbf" 2>/dev/null | wc -l)

echo ""
echo "=== Download Summary ==="
echo "✓ Font files ready in: data/fonts/"
echo "  Total font files: $FONT_COUNT"
echo ""
echo "These fonts include:"
echo "  - Open Sans (Regular, Bold, etc.)"
echo "  - Noto Sans (multilingual support)"
echo "  - Other MapBox GL compatible fonts"
echo ""
echo "TileServer GL is configured to serve fonts from http://localhost:8080/data/glyphs"
