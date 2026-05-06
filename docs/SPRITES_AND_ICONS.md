# Sprites and Icons Guide

Complete guide for using and customizing sprites and icons in your Algerian TileServer GL setup.

## Overview

Sprites are sprite sheets containing multiple icon images. They're used to efficiently render map icons and symbols in MapLibre GL. This setup includes:

- **Maki Icons** - 600+ icons from MapBox's Maki project
- **OSM Bright Sprites** - Pre-built sprite sheets optimized for OpenStreetMap
- **High-DPI Support** - @2x versions for Retina displays
- **Icon Categories** - Pre-mapped icon names for POI rendering

## File Structure

```
data/
├── sprites/
│   ├── osm-liberty.png          # Standard resolution sprite sheet
│   ├── osm-liberty.json         # Sprite metadata
│   ├── osm-liberty@2x.png       # High-DPI sprite sheet
│   ├── osm-liberty@2x.json      # High-DPI metadata
│   └── README.md               # Sprite documentation
└── icons/
    ├── iconset.json            # Icon definitions and colors
    ├── categories.json         # POI to icon mappings
    ├── poi-layers.json         # MapLibre layer examples
    └── custom/                 # Your custom icons (optional)
```

## Setup

### Step 1: Download Sprites and Icons

```bash
bash scripts/setup-sprites.sh
```

This will:
1. Download Maki icon set from MapBox
2. Download OSM Liberty sprite sheets
3. Create icon category mappings
4. Generate documentation

Expected downloads:
- `osm-liberty.png` (~80KB)
- `osm-liberty@2x.png` (~320KB)
- Maki icon set (optional, for customization)

### Step 2: Verify Installation

Check that sprite files exist:

```bash
ls -lh data/sprites/osm-liberty*.{png,json}
```

You should see 4 files:
- osm-liberty.json
- osm-liberty.png
- osm-liberty@2x.json
- osm-liberty@2x.png

### Step 3: Start TileServer GL

Sprites are automatically served at:

```
http://localhost:8080/sprites/osm-liberty
http://localhost:8080/sprites/osm-liberty@2x
```

## MapLibre GL Configuration

### Setting Up Sprites in Your Style

Add to your style JSON:

```json
{
  "version": 8,
  "name": "Your Map Style",
  "sprite": "http://localhost:8080/sprites/osm-liberty",
  "sources": { ... },
  "layers": [ ... ]
}
```

**Remote Access:**

If accessing from another device/network:

```json
{
  "sprite": "http://192.168.1.100:8080/sprites/osm-liberty"
}
```

Replace `192.168.1.100` with your server's IP address.

### Using Icons in Layers

Add a symbol layer with icons:

```json
{
  "id": "poi-icons",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "layout": {
    "icon-image": "restaurant-15",
    "icon-size": 1.0,
    "icon-allow-overlap": false,
    "icon-anchor": "bottom",
    "text-field": ["get", "name"],
    "text-font": ["Open Sans Regular"],
    "text-offset": [0, 1.2],
    "text-size": 12
  },
  "paint": {
    "text-color": "#626262",
    "text-halo-color": "#ffffff",
    "text-halo-width": 1.2
  }
}
```

### Dynamic Icons Based on POI Type

Use Maki property to automatically select icons:

```json
{
  "id": "poi-icons-dynamic",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "layout": {
    "icon-image": ["concat", ["get", "maki"], "-15"],
    "icon-size": [
      "interpolate",
      ["linear"],
      ["zoom"],
      10, 0.8,
      15, 1.2,
      18, 1.5
    ],
    "icon-allow-overlap": false,
    "icon-anchor": "bottom"
  }
}
```

## Available Icons

### Amenity Icons

| Name | Type | Icon |
|------|------|------|
| restaurant | Food | 🍽️ |
| cafe | Food | ☕ |
| bar | Food | 🍺 |
| shop | Retail | 🏪 |
| supermarket | Retail | 🛒 |
| bakery | Food | 🥐 |
| bank | Finance | 🏦 |
| atm | Finance | 💳 |
| pharmacy | Health | 💊 |
| hospital | Health | 🏥 |
| clinic | Health | ⚕️ |
| post | Services | 📮 |
| parking | Transport | 🅿️ |
| fuel | Transport | ⛽ |

### Tourism Icons

| Name | Type | Icon |
|------|------|------|
| hotel | Accommodation | 🏨 |
| hostel | Accommodation | 🏠 |
| guest_house | Accommodation | 🏡 |
| attraction | Attraction | 🎡 |
| museum | Culture | 🏛️ |
| zoo | Nature | 🦁 |
| viewpoint | Nature | 🔭 |
| information | Services | ℹ️ |

### Transportation Icons

| Name | Type | Icon |
|------|------|------|
| bus_stop | Transit | 🚌 |
| train_station | Transit | 🚂 |
| airport | Air | ✈️ |
| ferry | Water | ⛴️ |
| taxi | Road | 🚕 |

### Infrastructure Icons

| Name | Type | Icon |
|------|------|------|
| school | Education | 🏫 |
| university | Education | 🎓 |
| library | Education | 📚 |
| police | Safety | 👮 |
| fire | Safety | 🚒 |

## Icon Sizes

Maki icons come in standard sizes:

- **11px** - Very small, for high zoom levels (18+)
- **15px** - Small, for medium zoom levels (12-17)
- **22px** - Large, for low zoom levels (0-11)

Reference in your style:

```json
{
  "layout": {
    "icon-image": "restaurant-15"  // Size 15
  }
}
```

### Zoom-Based Icon Sizing

Dynamically adjust size by zoom:

```json
{
  "layout": {
    "icon-image": "restaurant-15",
    "icon-size": [
      "interpolate",
      ["linear"],
      ["zoom"],
      10, 0.6,     // 60% at zoom 10
      12, 0.8,     // 80% at zoom 12
      15, 1.0,     // 100% at zoom 15
      18, 1.3      // 130% at zoom 18
    ]
  }
}
```

## High-DPI (Retina) Support

The setup includes high-resolution sprites for sharp rendering on Retina displays.

**TileServer GL automatically serves the correct version:**

- Standard: `/sprites/osm-liberty.png`
- Retina: `/sprites/osm-liberty@2x.png`

MapLibre GL will automatically use @2x versions on high-DPI devices.

## Customizing Icons

### Using Maki Editor

1. Visit [Maki Editor](https://labs.mapbox.com/maki/)
2. Select your custom icons
3. Download as SVG and JSON
4. Generate new sprite sheets

### Generating Custom Sprites

If you modify icons, regenerate sprites using Spritezero:

```bash
# Install spritezero (requires Node.js)
npm install -g @mapbox/spritezero-cli

# Generate from SVGs
spritezero ./data/sprites/osm-liberty ./svgs

# Generate high-DPI version
spritezero --ratio 2 ./data/sprites/osm-liberty@2x ./svgs
```

Expected output:
- `osm-liberty.png` + `osm-liberty.json`
- `osm-liberty@2x.png` + `osm-liberty@2x.json`

### Adding Custom Icons

For custom icons not in Maki:

1. Create SVG file (recommended: 24x24px)
2. Place in `data/icons/custom/` directory
3. Regenerate sprites with Spritezero
4. Reference in your style: `icon-image: "my-custom-icon-15"`

## React Native Integration

### MapLibre Native Setup

Reference sprites in your React Native MapLibre setup:

```jsx
import MapLibGL from '@react-native-mapbox-gl/maps';

export default function AlgeriaMapWithIcons() {
  const styleURL = 'http://192.168.1.100:8080/styles/osm-liberty/style.json';

  return (
    <MapLibGL.MapView
      styleURL={styleURL}
      centerCoordinate={[5.5, 28.0]}
      zoomLevel={8}
    >
      {/* Sprites are automatically rendered from style */}
      <MapLibGL.Camera
        centerCoordinate={[5.5, 28.0]}
        zoomLevel={8}
      />
    </MapLibGL.MapView>
  );
}
```

**Key Points:**
- Sprites load from TileServer GL style
- No additional configuration needed
- Icons render automatically based on style layers
- High-DPI sprites used on Retina devices

## POI Layer Example

Complete example adding POI icons to your style:

```json
{
  "id": "poi-icons",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "minzoom": 10,
  "filter": [
    "all",
    ["!=", "name", ""],
    ["has", "maki"]
  ],
  "layout": {
    "icon-image": [
      "case",
      ["has", "maki"],
      ["concat", ["get", "maki"], "-15"],
      "attraction-15"
    ],
    "icon-size": [
      "interpolate",
      ["linear"],
      ["zoom"],
      10, 0.8,
      15, 1.0,
      18, 1.3
    ],
    "icon-allow-overlap": false,
    "icon-anchor": "bottom",
    "icon-padding": 2,
    "text-field": ["get", "name"],
    "text-font": ["Open Sans Regular", "Arial Unicode MS Regular"],
    "text-size": [
      "interpolate",
      ["linear"],
      ["zoom"],
      10, 10,
      15, 12,
      18, 14
    ],
    "text-offset": [0, 1.5],
    "text-anchor": "top",
    "text-max-width": 8,
    "text-line-height": 1.2
  },
  "paint": {
    "text-color": "#626262",
    "text-halo-color": "#ffffff",
    "text-halo-width": 1.2,
    "text-opacity": [
      "interpolate",
      ["linear"],
      ["zoom"],
      10, 0.6,
      12, 0.8,
      15, 1.0
    ]
  }
}
```

## Troubleshooting

### Icons Not Appearing

**Problem:** Icons show as missing image placeholder

**Solutions:**

1. Verify sprite files exist:
   ```bash
   ls -lh data/sprites/osm-liberty*.png
   ```

2. Check sprite URL in style is correct:
   ```json
   {
     "sprite": "http://localhost:8080/sprites/osm-liberty"
   }
   ```

3. Verify TileServer GL is running:
   ```bash
   curl http://localhost:8080/sprites/osm-liberty.json
   ```

4. Check browser console for 404 errors
5. Ensure icon names match sprite metadata

### Icons Blurry on Retina

**Solution:** Verify @2x sprites are being served:

```bash
# Check file sizes - @2x should be ~4x larger
ls -lh data/sprites/osm-liberty*.png

# Monitor requests in browser DevTools
# Should show osm-liberty@2x.png on high-DPI devices
```

### Wrong Icons Displaying

**Problem:** Wrong icon shows for POI

**Solutions:**

1. Check the `maki` property value in your data
2. Verify icon name exists in sprite metadata
3. Use fallback icons:
   ```json
   {
     "icon-image": [
       "case",
       ["has", "maki"],
       ["concat", ["get", "maki"], "-15"],
       "attraction-15"
     ]
   }
   ```

### Sprites Don't Load Remotely

**Problem:** "Cannot load sprites" when accessing from another device

**Solutions:**

1. Use server IP instead of localhost:
   ```json
   {
     "sprite": "http://192.168.1.100:8080/sprites/osm-liberty"
   }
   ```

2. Enable CORS in TileServer GL config:
   ```json
   {
     "allow_cors": true
   }
   ```

3. Verify network connectivity:
   ```bash
   curl http://192.168.1.100:8080/sprites/osm-liberty.json
   ```

## Performance Tips

### Optimize Icon Rendering

1. **Set minzoom** for icon layers to avoid rendering at low zooms:
   ```json
   {
     "minzoom": 12,
     "layout": { ... }
   }
   ```

2. **Use icon-allow-overlap wisely:**
   ```json
   {
     "icon-allow-overlap": false,  // Prevent overlapping icons
     "icon-ignore-placement": false
   }
   ```

3. **Limit visible icons** with filters:
   ```json
   {
     "filter": ["!=", "name", ""]
   }
   ```

### Sprite Caching

TileServer GL caches sprites by default. Set cache headers:

```json
{
  "cache": 3600  // 1 hour cache
}
```

## Creating Custom Icon Packs

### Structure

```
data/icons/packs/
├── algeria-attractions/
│   ├── style.json
│   ├── icons/
│   │   ├── icon1.svg
│   │   ├── icon2.svg
│   │   └── ...
│   └── iconset.json
└── algeria-transport/
    └── ...
```

### Serving Multiple Sprites

MapLibre GL 3.0+ supports multiple sprites:

```json
{
  "sprite": [
    {"id": "default", "url": "http://localhost:8080/sprites/osm-liberty"},
    {"id": "custom", "url": "http://localhost:8080/sprites/custom"}
  ],
  "layers": [
    {
      "layout": {
        "icon-image": ["case", ["has", "custom_icon"], ["concat", "custom:", ["get", "custom_icon"]], ["concat", "default:", ["get", "maki"]]]
      }
    }
  ]
}
```

## Resources

- [Maki Icons](https://labs.mapbox.com/maki/)
- [Spritezero](https://github.com/mapbox/spritezero)
- [MapLibre Sprite Spec](https://maplibre.org/maplibre-gl-js/docs/API/types/StyleSpecification/)
- [OSM Liberty Sprites](https://github.com/openmaptiles/osm-liberty-gl-style)
- [OpenMapTiles Icons](https://openmaptiles.org/)

## License

- **Maki Icons**: CC-0 (Public Domain)
- **OSM Liberty Sprites**: CC-0 (Public Domain)
- **Custom modifications**: Share as CC-0 or your chosen license
