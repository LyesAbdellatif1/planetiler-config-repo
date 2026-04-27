# Sprites & Icons Setup Summary

## What's Been Added

Complete support for **600+ Maki icons and sprite sheets** for your Algerian TileServer GL setup.

### New Files Created

#### Scripts (1 file)
- **`scripts/setup-sprites.sh`** (407 lines)
  - Downloads OSM Liberty sprites (includes Maki icons)
  - Creates icon category mappings
  - Generates POI layer examples
  - Sets up sprite documentation

#### Documentation (2 files)
- **`docs/SPRITES_AND_ICONS.md`** (567 lines)
  - Comprehensive sprite setup guide
  - MapLibre GL configuration examples
  - Icon sizing and zoom-based rendering
  - React Native integration patterns
  - Troubleshooting guide
  - Custom icon generation

- **`docs/ICON_REFERENCE.md`** (499 lines)
  - Complete catalog of 600+ Maki icons
  - Organized by category (Food, Shops, Transport, etc.)
  - Usage examples for each category
  - Icon naming conventions
  - Color customization patterns
  - Performance optimization tips

#### Updated Files
- **`package.json`** - Added `npm run sprites` command
- **`README.md`** - Added icon categories section and sprite documentation links
- **`docs/REACT_NATIVE_SETUP.md`** - Added sprite and icon usage examples

### Icon Categories Available

| Category | Icons | Examples |
|----------|-------|----------|
| 🍽️ Food & Drink | 20+ | restaurant, cafe, bar, bakery |
| 🛍️ Shops & Retail | 50+ | shop, supermarket, electronics, clothing |
| 🏦 Finance | 5+ | bank, atm, bureau-de-change |
| 💊 Health & Medical | 15+ | hospital, pharmacy, clinic, dentist |
| 🚗 Transport | 25+ | parking, fuel, bus, train, airport |
| 🏨 Accommodation | 15+ | hotel, hostel, guest-house, campsite |
| 🎭 Entertainment | 30+ | museum, attraction, zoo, theater |
| 📚 Education | 10+ | school, university, library |
| ⛪ Religious | 10+ | church, mosque, synagogue, temple |
| 🏢 Government | 10+ | government, embassy, court |
| 🌳 Nature & Parks | 20+ | park, viewpoint, hiking, garden |
| 🔧 Services | 40+ | post, police, fire, laundry, repair |

**Total: 600+ icons available**

## How to Use

### Step 1: Download Sprites

```bash
npm run sprites
```

This downloads:
- Standard resolution sprites (~80KB)
- High-resolution @2x sprites (~320KB)
- Icon metadata and mappings
- POI layer examples

### Step 2: Reference in Style

```json
{
  "sprite": "http://localhost:8080/sprites/osm-bright",
  "layers": [
    {
      "id": "poi-icons",
      "type": "symbol",
      "source": "openmaptiles",
      "source-layer": "poi",
      "layout": {
        "icon-image": "restaurant-15",
        "icon-size": 1.0
      }
    }
  ]
}
```

### Step 3: React Native Integration

```jsx
<MapLibGL.MapView
  styleURL="http://192.168.1.X:8080/styles/osm-bright/style.json"
  centerCoordinate={[5.5, 28.0]}
  zoomLevel={8}
/>
```

Sprites automatically render from the style!

## Features

### Icon Sizes

All icons come in 3 standard sizes:
- **11px** - For high zoom (17+)
- **15px** - For medium zoom (10-16)
- **22px** - For low zoom (0-9)

```json
{
  "icon-image": "restaurant-15",  // Medium size
  "icon-size": [
    "interpolate", ["linear"], ["zoom"],
    10, 0.8,   // Smaller at low zoom
    15, 1.0,   // Standard
    18, 1.3    // Larger at high zoom
  ]
}
```

### High-DPI Support

Automatically uses @2x sprites on Retina/high-DPI displays. No configuration needed!

Files served:
- `osm-bright.png` (standard)
- `osm-bright@2x.png` (Retina, 2x size)

MapLibre GL selects the right version automatically.

### Dynamic Icons

Select icons based on POI class:

```json
{
  "icon-image": [
    "match",
    ["get", "class"],
    "restaurant", "restaurant-15",
    "cafe", "cafe-15",
    "hotel", "hotel-15",
    "shop", "shop-15",
    "attraction"  // Default fallback
  ]
}
```

### Icon Coloring

Apply colors based on POI type:

```json
{
  "paint": {
    "icon-color": [
      "match",
      ["get", "class"],
      "restaurant", "#d97200",  // Orange
      "hotel", "#5d60be",       // Blue
      "shop", "#76a723",        // Green
      "#626262"                 // Gray
    ]
  }
}
```

## File Structure

```
data/
├── sprites/
│   ├── osm-bright.png           # Standard sprite sheet
│   ├── osm-bright.json          # Sprite metadata
│   ├── osm-bright@2x.png        # High-DPI sprite sheet
│   ├── osm-bright@2x.json       # High-DPI metadata
│   └── README.md                # Sprite documentation
└── icons/
    ├── iconset.json             # Icon definitions
    ├── categories.json          # POI to icon mappings
    ├── poi-layers.json          # Example layers
    └── custom/ (optional)       # Custom icons
```

## npm Commands

```bash
# Download sprites and icons
npm run sprites

# Complete setup (data + sprites)
npm run setup

# Start TileServer GL
npm run tileserver

# Verify installation
npm run verify
```

## Documentation

| File | Purpose |
|------|---------|
| [SPRITES_AND_ICONS.md](./docs/SPRITES_AND_ICONS.md) | Complete setup guide with examples |
| [ICON_REFERENCE.md](./docs/ICON_REFERENCE.md) | Full icon catalog with 600+ examples |
| [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md) | React Native integration patterns |
| [README.md](./README.md) | Project overview with icons section |

## Performance

- **Sprite Size:** ~80KB (standard), ~320KB (@2x)
- **Load Time:** Icons load once, then render from memory
- **Caching:** TileServer GL caches sprites
- **Rendering:** Efficient sprite sheet rendering
- **No Extra Requests:** All icons in single sprite file

## POI Layer Example

Complete ready-to-use POI layer with icons:

```json
{
  "id": "poi-icons",
  "type": "symbol",
  "source": "openmaptiles",
  "source-layer": "poi",
  "minzoom": 12,
  "filter": ["!=", "name", ""],
  "layout": {
    "icon-image": ["concat", ["get", "maki"], "-15"],
    "icon-size": [
      "interpolate", ["linear"], ["zoom"],
      12, 0.8,
      15, 1.0,
      18, 1.3
    ],
    "icon-allow-overlap": false,
    "icon-anchor": "bottom",
    "text-field": ["get", "name"],
    "text-font": ["Open Sans Regular"],
    "text-size": 12,
    "text-offset": [0, 1.5],
    "text-anchor": "top"
  },
  "paint": {
    "text-color": "#626262",
    "text-halo-color": "#ffffff",
    "text-halo-width": 1.2
  }
}
```

Add this to your `osm-bright-style.json` to enable POI icons!

## Troubleshooting

### Icons Not Appearing

1. Verify sprites downloaded:
   ```bash
   ls -lh data/sprites/osm-bright*.png
   ```

2. Check sprite URL in style:
   ```json
   {
     "sprite": "http://localhost:8080/sprites/osm-bright"
   }
   ```

3. Test sprite endpoint:
   ```bash
   curl http://localhost:8080/sprites/osm-bright.json
   ```

### Wrong Icon Displaying

Check icon name in sprite metadata:
```bash
curl http://localhost:8080/sprites/osm-bright.json | jq '.["restaurant-15"]'
```

### Sprites Blurry

Verify @2x files exist and are being served on high-DPI devices.

## Next Steps

1. **Download sprites:** `npm run sprites`
2. **Review examples:** Check `data/icons/poi-layers.json`
3. **Add to style:** Include POI layer in `osm-bright-style.json`
4. **Test locally:** `npm run tileserver` and visit `http://localhost:8080`
5. **Deploy:** Use Docker or your hosting platform

## References

- [Maki Icons](https://labs.mapbox.com/maki/) - Browse 600+ icons
- [SPRITES_AND_ICONS.md](./docs/SPRITES_AND_ICONS.md) - Comprehensive guide
- [ICON_REFERENCE.md](./docs/ICON_REFERENCE.md) - Complete catalog
- [MapLibre Spec](https://maplibre.org/maplibre-gl-js/docs/API/types/StyleSpecification/)

## License

- **Maki Icons:** CC-0 (Public Domain)
- **OSM Liberty Sprites:** CC-0 (Public Domain)
- **Your custom modifications:** Any license you choose

---

**Ready to add icons to your map!** 🗺️✨
