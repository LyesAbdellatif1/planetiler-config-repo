# React Native MapLibre Integration Guide

This guide explains how to integrate your Algerian OpenStreetMap tiles with a React Native MapLibre application.

## Prerequisites

- React Native project with Expo or bare React Native setup
- TileServer GL running locally or deployed remotely
- MapLibre Native installed in your React Native project

## Installation

### 1. Install MapLibre Native

```bash
# Using Expo
expo install @react-native-mapbox-gl/maps

# Or using npm/yarn
npm install @react-native-mapbox-gl/maps
# or
yarn add @react-native-mapbox-gl/maps
```

### 2. Install additional dependencies

```bash
npm install react-native-gesture-handler @react-native-community/geolocation
```

## Setup

### 1. Configure Native Dependencies (if using bare React Native)

For Android (`android/app/build.gradle`):
```gradle
dependencies {
    implementation 'com.mapbox.mapboxsdk:mapbox-android-sdk:9.4.0'
    implementation 'com.mapbox.mapboxsdk:mapbox-android-plugin-annotation-v8:0.8.0'
}
```

For iOS, use CocoaPods:
```bash
cd ios && pod install && cd ..
```

### 2. Add Permissions

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
<uses-permission android:name="android.permission.INTERNET" />
```

**iOS** (`ios/YourApp/Info.plist`):
```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>We need your location to show it on the map</string>
```

## Basic Map Component

### Example 1: Simple Map Display

```jsx
import React from 'react';
import { StyleSheet, View } from 'react-native';
import MapLibGL from '@react-native-mapbox-gl/maps';

// Configure MapLibre with your tile server
MapLibGL.setSourceDefaultOptions({
  maxOverzoomLevel: 10,
  minOverzoomLevel: 0,
});

const TILESERVER_URL = 'http://192.168.1.X:8080'; // Replace with your server IP
const STYLE_URL = `${TILESERVER_URL}/styles/osm-liberty/style.json`;

export default function AlgeriaMap() {
  return (
    <View style={styles.container}>
      <MapLibGL.MapView
        style={styles.map}
        styleURL={STYLE_URL}
        centerCoordinate={[5.5, 28.0]}
        zoomLevel={4}
        scrollEnabled={true}
        zoomEnabled={true}
        rotateEnabled={true}
        pitchEnabled={true}
      >
        <MapLibGL.Camera
          zoomLevel={4}
          centerCoordinate={[5.5, 28.0]}
          pitch={0}
          heading={0}
        />
      </MapLibGL.MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
});
```

### Example 2: Map with User Location

```jsx
import React, { useState, useEffect } from 'react';
import { StyleSheet, View, Text, Alert } from 'react-native';
import MapLibGL from '@react-native-mapbox-gl/maps';
import Geolocation from '@react-native-community/geolocation';

const TILESERVER_URL = 'http://192.168.1.X:8080';
const STYLE_URL = `${TILESERVER_URL}/styles/osm-liberty/style.json`;

export default function AlgeriaMapWithLocation() {
  const [location, setLocation] = useState(null);

  useEffect(() => {
    // Request location permission and get user location
    Geolocation.getCurrentPosition(
      (position) => {
        const { latitude, longitude } = position.coords;
        setLocation([longitude, latitude]);
      },
      (error) => {
        console.warn('Error getting location:', error);
        Alert.alert('Location Error', 'Could not get your location');
      }
    );
  }, []);

  return (
    <View style={styles.container}>
      <MapLibGL.MapView
        style={styles.map}
        styleURL={STYLE_URL}
        centerCoordinate={location || [5.5, 28.0]}
        zoomLevel={location ? 12 : 4}
      >
        <MapLibGL.Camera
          zoomLevel={location ? 12 : 4}
          centerCoordinate={location || [5.5, 28.0]}
        />
        {location && (
          <MapLibGL.PointAnnotation
            id="userLocation"
            coordinate={location}
            title="Your Location"
          >
            <View style={styles.marker} />
          </MapLibGL.PointAnnotation>
        )}
      </MapLibGL.MapView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
  marker: {
    width: 20,
    height: 20,
    borderRadius: 10,
    backgroundColor: '#FF6B6B',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
});
```

### Example 3: Map with Markers and Info

```jsx
import React, { useState } from 'react';
import { StyleSheet, View, Text } from 'react-native';
import MapLibGL from '@react-native-mapbox-gl/maps';

const TILESERVER_URL = 'http://192.168.1.X:8080';
const STYLE_URL = `${TILESERVER_URL}/styles/osm-liberty/style.json`;

const ALGERIA_CITIES = [
  { id: 1, name: 'Algiers', coordinates: [3.0588, 36.7372] },
  { id: 2, name: 'Oran', coordinates: [-0.6417, 35.7325] },
  { id: 3, name: 'Constantine', coordinates: [6.6149, 36.3619] },
  { id: 4, name: 'Annaba', coordinates: [7.768, 36.9068] },
  { id: 5, name: 'Tlemcen', coordinates: [-1.3175, 35.2972] },
];

export default function AlgeriaMapWithMarkers() {
  const [selectedCity, setSelectedCity] = useState(null);

  return (
    <View style={styles.container}>
      <MapLibGL.MapView
        style={styles.map}
        styleURL={STYLE_URL}
        centerCoordinate={[5.5, 28.0]}
        zoomLevel={4}
      >
        <MapLibGL.Camera
          zoomLevel={4}
          centerCoordinate={[5.5, 28.0]}
        />
        
        {ALGERIA_CITIES.map((city) => (
          <MapLibGL.PointAnnotation
            key={city.id}
            id={`city-${city.id}`}
            coordinate={city.coordinates}
            title={city.name}
            onSelected={() => setSelectedCity(city)}
          >
            <View style={styles.annotation} />
          </MapLibGL.PointAnnotation>
        ))}
      </MapLibGL.MapView>

      {selectedCity && (
        <View style={styles.infoBox}>
          <Text style={styles.infoTitle}>{selectedCity.name}</Text>
          <Text style={styles.infoCoords}>
            {selectedCity.coordinates[0].toFixed(4)}, {selectedCity.coordinates[1].toFixed(4)}
          </Text>
        </View>
      )}
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  map: {
    flex: 1,
  },
  annotation: {
    width: 24,
    height: 24,
    borderRadius: 12,
    backgroundColor: '#FF6B6B',
    borderWidth: 2,
    borderColor: '#FFFFFF',
  },
  infoBox: {
    position: 'absolute',
    bottom: 20,
    left: 20,
    right: 20,
    backgroundColor: '#FFFFFF',
    padding: 12,
    borderRadius: 8,
    elevation: 5,
    shadowColor: '#000',
    shadowOpacity: 0.3,
    shadowRadius: 4,
  },
  infoTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#333333',
  },
  infoCoords: {
    fontSize: 12,
    color: '#666666',
    marginTop: 4,
  },
});
```

## Configuration for Different Environments

### Local Development (on same network)

```javascript
const TILESERVER_URL = 'http://192.168.1.100:8080'; // Your machine's local IP
const STYLE_URL = `${TILESERVER_URL}/styles/osm-liberty/style.json`;
```

### Remote Server

```javascript
const TILESERVER_URL = 'https://your-domain.com'; // Your deployed server
const STYLE_URL = `${TILESERVER_URL}/styles/osm-liberty/style.json`;
```

### Custom Tile Sources

If you want to use specific layers from your tiles:

```jsx
<MapLibGL.MapView style={styles.map}>
  <MapLibGL.VectorSource
    id="algeria-tiles"
    url={`${TILESERVER_URL}/data/algeria/tilesets/algeria.json`}
  >
    <MapLibGL.FillLayer
      id="water-fill"
      sourceLayerID="water"
      style={{
        fillColor: '#c8e6f8',
      }}
    />
    <MapLibGL.LineLayer
      id="road-lines"
      sourceLayerID="road"
      style={{
        lineColor: '#ffd966',
        lineWidth: 2,
      }}
    />
  </MapLibGL.VectorSource>
</MapLibGL.MapView>
```

## Troubleshooting

### Issue: Tiles not loading

**Solution:**
1. Ensure TileServer GL is running: `curl http://localhost:8080`
2. Check that your server URL is correct for your network
3. On Android, ensure `android.permission.INTERNET` is granted
4. Check network firewall settings

### Issue: Styles not applying

**Solution:**
1. Verify the style URL is accessible: `curl http://your-server:8080/styles/osm-liberty/style.json`
2. Ensure fonts are being served correctly
3. Check browser console for CORS errors

### Issue: Performance issues

**Solution:**
1. Reduce zoom level complexity
2. Limit the number of annotations/markers
3. Use layer filtering to show only relevant features
4. Implement map bounds to avoid loading unnecessary data

## Using Sprites and Icons

Your TileServer GL includes sprite sheets with 600+ icons (Maki icons). Add icons to your map:

### Adding POI Icons to Map

```jsx
import MapLibGL from '@react-native-mapbox-gl/maps';

export default function AlgeriaMapWithIcons() {
  const styleURL = 'http://192.168.1.X:8080/styles/osm-liberty/style.json';

  // Custom style with POI icons
  const customStyle = {
    version: 8,
    name: 'Algeria with POI Icons',
    sprite: 'http://192.168.1.X:8080/sprites/osm-liberty',
    sources: { /* ... */ },
    layers: [
      // ... existing layers ...
      {
        id: 'poi-icons',
        type: 'symbol',
        source: 'openmaptiles',
        'source-layer': 'poi',
        minzoom: 12,
        layout: {
          'icon-image': ['concat', ['get', 'maki'], '-15'],
          'icon-size': [
            'interpolate',
            ['linear'],
            ['zoom'],
            12, 0.8,
            15, 1.0,
            18, 1.3
          ],
          'icon-allow-overlap': false,
          'icon-anchor': 'bottom',
          'text-field': ['get', 'name'],
          'text-font': ['Open Sans Regular'],
          'text-size': 12,
          'text-offset': [0, 1.2],
          'text-anchor': 'top'
        },
        paint: {
          'text-color': '#626262',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1.2
        }
      }
    ]
  };

  return (
    <View style={styles.container}>
      <MapLibGL.MapView
        styleURL={styleURL}
        centerCoordinate={[5.5, 28.0]}
        zoomLevel={8}
      >
        <MapLibGL.Camera
          centerCoordinate={[5.5, 28.0]}
          zoomLevel={8}
        />
      </MapLibGL.MapView>
    </View>
  );
}
```

### Icon Categories Available

Common icons included in your sprite:

**Food & Drink:**
- `restaurant-15`, `cafe-15`, `bar-15`, `bakery-15`

**Shops:**
- `shop-15`, `supermarket-15`, `bank-15`, `atm-15`

**Accommodation:**
- `hotel-15`, `hostel-15`, `guest_house-15`

**Tourism:**
- `museum-15`, `attraction-15`, `zoo-15`, `viewpoint-15`

**Transport:**
- `bus-15`, `train-15`, `airport-15`, `parking-15`, `fuel-15`

**Services:**
- `hospital-15`, `pharmacy-15`, `school-15`, `post-15`, `police-15`

**Icon Sizes:** `-11` (small), `-15` (medium), `-22` (large)

### Filtering Icons by Type

Show only specific POI types:

```jsx
{
  id: 'restaurant-icons',
  type: 'symbol',
  source: 'openmaptiles',
  'source-layer': 'poi',
  filter: ['==', 'class', 'restaurant'],
  layout: {
    'icon-image': 'restaurant-15',
    'icon-size': 1.0,
    'text-field': ['get', 'name'],
    'text-font': ['Open Sans Regular'],
    'text-size': 12,
    'text-offset': [0, 1.2],
    'text-anchor': 'top'
  }
}
```

### Custom Icon Colors

Color icons using the paint property with filters:

```jsx
{
  id: 'poi-icons-colored',
  type: 'symbol',
  source: 'openmaptiles',
  'source-layer': 'poi',
  layout: {
    'icon-image': ['concat', ['get', 'maki'], '-15'],
    'icon-size': 1.0
  },
  paint: {
    'icon-color': [
      'match',
      ['get', 'class'],
      'restaurant', '#d97200',  // Orange for restaurants
      'hotel', '#5d60be',       // Blue for hotels
      'shop', '#76a723',        // Green for shops
      '#626262'                 // Default gray
    ]
  }
}
```

## Performance Tips

1. **Limit zoom levels**: Only show detailed features at appropriate zoom levels
2. **Use layer filtering**: Filter tiles server-side for better performance
3. **Cluster markers**: Use clustering for large marker datasets
4. **Optimize style**: Simplify paint properties and use efficient expressions
5. **Cache tiles**: TileServer GL caches tiles; configure appropriate cache times
6. **Icon sizing**: Use `icon-size` interpolation to scale icons by zoom level

## References

- [MapLibre Native Documentation](https://maplibre.org/maplibre-native/)
- [TileServer GL Documentation](https://tileserver.readthedocs.io/)
- [OpenMapTiles Documentation](https://openmaptiles.org/)
- [MapBox GL Style Specification](https://maplibre.org/maplibre-gl-js/docs/API/types/StyleSpecification/)

## Support

For issues with TileServer GL setup, see the main README.md in the root directory.
For MapLibre Native issues, consult the [MapLibre GitHub](https://github.com/maplibre/maplibre-native).
