# Quick Start Guide - 5 Minutes

Get Algerian tiles and React Native maps running in 5 minutes.

## Prerequisites

- Node.js 14+ (`node -v` to check)
- 200MB disk space for OSM data
- Internet connection for downloads

## Step 1: Verify Setup (1 minute)

```bash
bash scripts/verify-setup.sh
```

This checks all requirements. If anything is missing, instructions will appear.

## Step 2: Download Data (3 minutes)

```bash
bash scripts/download-algeria-data.sh
```

Downloads Algerian OpenStreetMap data (~200MB).

This is the command to use : 
& "C:\Program Files\Git\bin\bash.exe" scripts/download-algeria-data.sh

## Step 3: Install TileServer GL (1 minute)

```bash
npm install -g @mapbox/tileserver-gl-cli
```

Or use npm without global install:

```bash
npm install
npm run tileserver
```

## Step 4: Start Server

```bash
npm run tileserver
```

You'll see:
```
[1:12 PM] Starting TileServer GL v4.x.x
[1:12 PM] Listening on port 8080
```

## Step 5: View Your Map

Open in browser:
```
http://localhost:8080
```

## Step 6: Use in React Native

```jsx
import MapLibGL from '@react-native-mapbox-gl/maps';

export default function AlgeriaMap() {
  return (
    <MapLibGL.MapView
      styleURL="http://192.168.1.X:8080/styles/osm-bright/style.json"
      centerCoordinate={[5.5, 28.0]}
      zoomLevel={4}
    />
  );
}
```

Replace `192.168.1.X` with your computer's local IP address.

## That's It! 🎉

You now have a working tile server for Algerian maps.

## Troubleshooting

### Port 8080 in use?

```bash
# Change port in tileserver-gl-config.json:
# "port": 8081

npm run tileserver
```

### Tiles not loading in React Native?

1. Check server is running: `curl http://localhost:8080`
2. Replace `localhost` with your computer's IP: `192.168.1.X`
3. Make sure device is on same network

### Need more features?

See full documentation:
- [TILESERVER_SETUP.md](./TILESERVER_SETUP.md) - Complete setup guide
- [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md) - Advanced React Native examples

## Common Commands

```bash
# Download data
npm run download

# Download fonts (for better text)
npm run fonts

# Start server
npm run tileserver

# Start with Docker
npm run docker-up

# Stop Docker
npm run docker-down

# Check health
npm run health
```

## Next Steps

1. **Processing Custom Tiles:** See [TILESERVER_SETUP.md](./TILESERVER_SETUP.md#step-2-process-osm-data-to-vector-tiles-optional)
2. **React Native Integration:** See [REACT_NATIVE_SETUP.md](./docs/REACT_NATIVE_SETUP.md)
3. **Production Deployment:** See [TILESERVER_SETUP.md](./TILESERVER_SETUP.md#deployment)
4. **Customizing Style:** Edit `osm-bright-style.json`

## Network Access

### Local Machine
```
http://localhost:8080
```

### Same Network (from phone/another computer)
```
http://192.168.1.X:8080
```
(Replace X with your computer's IP: `ipconfig` on Windows, `ifconfig` on Mac/Linux)

### From Internet
Deploy to cloud (see deployment docs)

---

Need help? Check the full [README.md](./README.md) or [TILESERVER_SETUP.md](./TILESERVER_SETUP.md#troubleshooting)
