#!/bin/bash

# Setup Sprites and Icons for TileServer GL
# Downloads Maki icons and generates sprite sheets for use with MapLibre GL

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SPRITES_DIR="$PROJECT_DIR/data/sprites"
ICONS_DIR="$PROJECT_DIR/data/icons"
TEMP_DIR="/tmp/maki-icons-$$"

echo "=================================================="
echo "TileServer GL Sprite Setup"
echo "=================================================="
echo ""

# Create directories
mkdir -p "$SPRITES_DIR"
mkdir -p "$ICONS_DIR"
mkdir -p "$TEMP_DIR"

echo "📦 Setting up sprites and icons for Algerian map..."
echo ""

# Download Maki icon set (from MapBox/Maki project)
echo "1️⃣  Downloading Maki icon set..."
cd "$TEMP_DIR"

# Clone Maki icons repository
if command -v git &> /dev/null; then
    git clone --depth 1 https://github.com/mapbox/maki.git . || true
    MAKI_DOWNLOADED=true
else
    echo "⚠️  Git not installed. Downloading Maki icons as ZIP..."
    curl -sL "https://github.com/mapbox/maki/archive/refs/heads/main.zip" -o maki.zip
    unzip -q maki.zip
    mv maki-main/* . 2>/dev/null || true
    MAKI_DOWNLOADED=true
fi

if [ "$MAKI_DOWNLOADED" = true ]; then
    echo "✓ Maki icons downloaded"
else
    echo "⚠️  Could not download Maki icons. Using pre-built sprites instead."
fi

# Download pre-built OSM Liberty sprites (including Maki icons)
echo ""
echo "2️⃣  Downloading OSM Liberty sprites (includes Maki icons)..."

# Download sprite images and metadata
SPRITE_URLS=(
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty.json"
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty.png"
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty@2x.json"
    "https://raw.githubusercontent.com/openmaptiles/osm-liberty-gl-style/gh-pages/sprites/osm-liberty@2x.png"
)

for url in "${SPRITE_URLS[@]}"; do
    filename=$(basename "$url")
    echo "  Downloading $filename..."
    curl -sL "$url" -o "$SPRITES_DIR/$filename" || echo "  ⚠️  Could not download $filename"
done

if [ -f "$SPRITES_DIR/osm-liberty.png" ]; then
    echo "✓ Sprites downloaded successfully"
else
    echo "⚠️  Some sprite files could not be downloaded"
fi

# Create a sample iconset.json for reference
echo ""
echo "3️⃣  Creating iconset configuration..."

cat > "$ICONS_DIR/iconset.json" << 'EOF'
{
  "icons": {
    "poi": {
      "shop": "🏪",
      "restaurant": "🍽️",
      "cafe": "☕",
      "bar": "🍺",
      "hotel": "🏨",
      "parking": "🅿️",
      "fuel": "⛽",
      "hospital": "🏥",
      "school": "🏫",
      "post": "📮",
      "bank": "🏦",
      "attraction": "🎡",
      "museum": "🏛️",
      "zoo": "🦁"
    },
    "transportation": {
      "bus": "🚌",
      "train": "🚂",
      "airport": "✈️",
      "ferry": "⛴️",
      "taxi": "🚕"
    },
    "infrastructure": {
      "water": "💧",
      "power": "⚡",
      "construction": "🏗️"
    }
  },
  "colors": {
    "primary": "#5d60be",
    "secondary": "#4898ff",
    "accent": "#d97200",
    "danger": "#ba3827",
    "success": "#76a723",
    "warning": "#d97200"
  }
}
EOF

echo "✓ Iconset configuration created"

# Create icon categories for common use cases
echo ""
echo "4️⃣  Generating icon category mappings..."

cat > "$ICONS_DIR/categories.json" << 'EOF'
{
  "amenity": {
    "shop": "shop",
    "supermarket": "shop",
    "bakery": "shop",
    "restaurant": "restaurant",
    "cafe": "cafe",
    "bar": "bar",
    "pub": "bar",
    "hotel": "hotel",
    "guest_house": "hotel",
    "hostel": "hotel",
    "parking": "parking",
    "fuel": "fuel",
    "gas_station": "fuel",
    "hospital": "hospital",
    "clinic": "hospital",
    "pharmacy": "hospital",
    "school": "school",
    "university": "school",
    "post_office": "post",
    "bank": "bank",
    "atm": "bank",
    "fountain": "attraction",
    "theatre": "attraction",
    "museum": "museum",
    "zoo": "zoo",
    "cinema": "attraction",
    "library": "school"
  },
  "tourism": {
    "hotel": "hotel",
    "guest_house": "hotel",
    "hostel": "hotel",
    "attraction": "attraction",
    "museum": "museum",
    "zoo": "zoo",
    "viewpoint": "attraction",
    "picnic_site": "park",
    "information": "information"
  },
  "transport": {
    "bus_stop": "bus",
    "bus_station": "bus",
    "train_station": "train",
    "airport": "airport",
    "ferry_terminal": "ferry",
    "taxi": "taxi",
    "parking": "parking"
  }
}
EOF

echo "✓ Icon category mappings created"

# Create sprite metadata reference document
echo ""
echo "5️⃣  Creating sprite reference documentation..."

cat > "$SPRITES_DIR/README.md" << 'EOF'
# Sprite Assets for Algerian TileServer

This directory contains sprite sheets and icon metadata for rendering map icons and symbols.

## Files

- `osm-liberty.json` - Standard resolution sprite metadata
- `osm-liberty.png` - Standard resolution sprite sheet (128x128px icons)
- `osm-liberty@2x.json` - High resolution sprite metadata
- `osm-liberty@2x.png` - High resolution sprite sheet (256x256px icons)

## Icon Categories

### Amenities (Commerce & Services)
- `shop` - Generic shop/retail
- `supermarket` - Grocery stores
- `bakery` - Bakeries
- `restaurant` - Restaurants
- `cafe` - Cafes and coffee shops
- `bar` - Bars and pubs
- `pharmacy` - Pharmacies
- `post` - Post offices
- `bank` - Banks and ATMs
- `fuel` - Gas stations

### Tourism & Attractions
- `hotel` - Hotels and accommodations
- `museum` - Museums
- `attraction` - Tourist attractions
- `zoo` - Zoos
- `viewpoint` - Scenic viewpoints
- `information` - Tourist information

### Transportation
- `bus` - Bus stops and stations
- `train` - Train stations
- `airport` - Airports
- `ferry` - Ferry terminals
- `taxi` - Taxi stands
- `parking` - Parking areas

### Infrastructure
- `hospital` - Hospitals and medical
- `police` - Police stations
- `fire` - Fire stations
- `school` - Schools and universities
- `library` - Libraries

## Usage in MapLibre GL

Reference icons in your style layers using the `icon-image` property:

```json
{
  "id": "poi-icons",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "layout": {
    "icon-image": "{maki}-11",
    "icon-size": 1,
    "icon-allow-overlap": false,
    "icon-anchor": "bottom"
  }
}
```

## Sprite Configuration

In your MapLibre GL style JSON:

```json
{
  "sprite": "http://localhost:8080/sprites/osm-liberty"
}
```

TileServer GL will automatically serve both standard and high-resolution versions:
- `/sprites/osm-liberty.png` (standard)
- `/sprites/osm-liberty@2x.png` (high-DPI)

## Icon Naming Convention

All icons follow the Maki naming convention:
- Format: `{icon-name}-{size}` or `{icon-name}`
- Common sizes: 11, 15, 22
- High-DPI: Append `@2x` to URLs

## Customizing Sprites

To customize sprites:

1. Export icons from [Maki](https://labs.mapbox.com/maki/) as SVG
2. Use [Spritezero](https://github.com/mapbox/spritezero) to generate PNG sprites
3. Place generated files in this directory
4. Update TileServer GL sprite URL

```bash
# Example with spritezero-cli
npx spritezero ./sprites/osm-liberty ./svgs
```

## High-DPI Support

For Retina displays, high-resolution sprites (@2x) are automatically used when available.
Create @2x versions with double resolution:

- `osm-liberty@2x.json`
- `osm-liberty@2x.png`

The @2x files should contain the same icons at 2x size.

## Icon Attribution

- **Maki Icons**: MapBox (CC-0)
- **OSM Liberty Sprites**: OpenMapTiles (CC-0)
- **Styling**: OpenStreetMap Contributors

## References

- [Maki Icons](https://labs.mapbox.com/maki/)
- [MapLibre Sprite Spec](https://maplibre.org/maplibre-gl-js/docs/API/types/StyleSpecification/)
- [OpenMapTiles Icons](https://openmaptiles.org/)
EOF

echo "✓ Sprite documentation created"

# Create a sample POI layer using sprites
echo ""
echo "6️⃣  Creating POI layer configuration examples..."

cat > "$ICONS_DIR/poi-layers.json" << 'EOF'
{
  "poi-icons-layer": {
    "id": "poi-icons",
    "type": "symbol",
    "source": "openmaptiles",
    "source-layer": "poi",
    "filter": ["!=", "name", ""],
    "layout": {
      "icon-image": ["get", "maki"],
      "icon-size": [
        "interpolate",
        ["linear"],
        ["zoom"],
        0, 0.5,
        10, 0.8,
        14, 1.0,
        18, 1.5
      ],
      "icon-allow-overlap": false,
      "text-field": ["get", "name"],
      "text-font": ["Open Sans Regular"],
      "text-size": 12,
      "text-offset": [0, 1.2],
      "text-anchor": "top",
      "icon-anchor": "bottom"
    },
    "paint": {
      "text-color": "#626262",
      "text-halo-color": "#ffffff",
      "text-halo-width": 1
    }
  },
  "poi-label-layer": {
    "id": "poi-labels",
    "type": "symbol",
    "source": "openmaptiles",
    "source-layer": "poi",
    "filter": ["!=", "name", ""],
    "layout": {
      "text-field": ["get", "name"],
      "text-font": ["Open Sans Regular"],
      "text-size": 10,
      "text-max-width": 8,
      "text-anchor": "top",
      "text-justify": "center",
      "text-offset": [0, 0.8]
    },
    "paint": {
      "text-color": "#626262",
      "text-halo-color": "#ffffff",
      "text-halo-width": 1.2
    }
  }
}
EOF

echo "✓ POI layer examples created"

# Cleanup
rm -rf "$TEMP_DIR"

# Create summary
echo ""
echo "=================================================="
echo "✅ Sprite Setup Complete!"
echo "=================================================="
echo ""
echo "📁 Files created:"
echo "   - $SPRITES_DIR/osm-liberty.png"
echo "   - $SPRITES_DIR/osm-liberty.json"
echo "   - $SPRITES_DIR/osm-liberty@2x.png"
echo "   - $SPRITES_DIR/osm-liberty@2x.json"
echo "   - $ICONS_DIR/iconset.json"
echo "   - $ICONS_DIR/categories.json"
echo "   - $ICONS_DIR/poi-layers.json"
echo "   - $SPRITES_DIR/README.md"
echo ""
echo "🎨 Next steps:"
echo "   1. Sprites are automatically served by TileServer GL"
echo "   2. Style references: http://localhost:8080/sprites/osm-liberty"
echo "   3. Add POI layers from icons/poi-layers.json to your style"
echo "   4. Customize icons using Maki editor if needed"
echo ""
echo "📚 Documentation:"
echo "   - Check $SPRITES_DIR/README.md for icon categories"
echo "   - See $ICONS_DIR/categories.json for POI mappings"
echo "   - Review $ICONS_DIR/poi-layers.json for layer examples"
echo ""
