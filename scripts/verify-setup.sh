#!/bin/bash

# Verify TileServer GL Setup for Algeria
# Checks all prerequisites and configurations

set -e

echo "=== TileServer GL Setup Verification ==="
echo ""

# Color codes
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

check_passed() {
    echo -e "${GREEN}✓${NC} $1"
}

check_failed() {
    echo -e "${RED}✗${NC} $1"
}

check_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# 1. Check Node.js
echo "1. Checking Node.js..."
if command -v node &> /dev/null; then
    NODE_VERSION=$(node -v)
    check_passed "Node.js installed: $NODE_VERSION"
else
    check_failed "Node.js not installed"
    echo "  Install from: https://nodejs.org/"
fi

# 2. Check npm
echo ""
echo "2. Checking npm..."
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm -v)
    check_passed "npm installed: $NPM_VERSION"
else
    check_failed "npm not installed"
fi

# 3. Check required files
echo ""
echo "3. Checking configuration files..."
CONFIG_FILES=(
    "tileserver-gl-config.json"
    "osm-bright-style.json"
    "planetiler-config.json"
    "docker-compose.yml"
    "Dockerfile"
)

for file in "${CONFIG_FILES[@]}"; do
    if [ -f "$file" ]; then
        check_passed "Found: $file"
    else
        check_failed "Missing: $file"
    fi
done

# 4. Check scripts
echo ""
echo "4. Checking scripts..."
SCRIPTS=(
    "scripts/download-algeria-data.sh"
    "scripts/download-fonts.sh"
    "scripts/process-tiles.js"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        check_passed "Found: $script"
    else
        check_failed "Missing: $script"
    fi
done

# 5. Check data directory
echo ""
echo "5. Checking data directory..."
if [ -d "data" ]; then
    check_passed "Data directory exists"
    
    if [ -f "data/algeria-latest.osm.pbf" ]; then
        SIZE=$(ls -lh data/algeria-latest.osm.pbf | awk '{print $5}')
        check_passed "OSM data downloaded: $SIZE"
    else
        check_warning "OSM data not yet downloaded (run: bash scripts/download-algeria-data.sh)"
    fi
    
    if [ -f "data/algeria.mbtiles" ]; then
        SIZE=$(ls -lh data/algeria.mbtiles | awk '{print $5}')
        check_passed "MBTiles generated: $SIZE"
    else
        check_warning "MBTiles not yet generated"
    fi
else
    check_failed "Data directory doesn't exist"
fi

# 6. Check Docker (optional)
echo ""
echo "6. Checking Docker (optional)..."
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version)
    check_passed "Docker installed: $DOCKER_VERSION"
else
    check_warning "Docker not installed (required for docker-compose)"
    echo "  Install from: https://www.docker.com/products/docker-desktop"
fi

# 7. Check Docker Compose (optional)
echo ""
echo "7. Checking Docker Compose (optional)..."
if command -v docker-compose &> /dev/null; then
    DOCKER_COMPOSE_VERSION=$(docker-compose --version)
    check_passed "Docker Compose installed: $DOCKER_COMPOSE_VERSION"
else
    check_warning "Docker Compose not installed"
fi

# 8. Check Java (optional, for tile processing)
echo ""
echo "8. Checking Java (optional, needed for Planetiler)..."
if command -v java &> /dev/null; then
    JAVA_VERSION=$(java -version 2>&1 | grep version | awk -F'"' '{print $2}')
    check_passed "Java installed: $JAVA_VERSION"
else
    check_warning "Java not installed (needed to process OSM data)"
    echo "  Install from: https://www.oracle.com/java/technologies/downloads/"
fi

# 9. Check TileServer GL
echo ""
echo "9. Checking TileServer GL..."
if npm list -g @mapbox/tileserver-gl-cli &> /dev/null; then
    VERSION=$(npm list -g @mapbox/tileserver-gl-cli 2>/dev/null | grep tileserver-gl | awk '{print $2}')
    check_passed "TileServer GL installed globally: $VERSION"
else
    check_warning "TileServer GL not installed globally"
    echo "  Install with: npm install -g @mapbox/tileserver-gl-cli"
fi

# 10. Check port availability
echo ""
echo "10. Checking port availability..."
if command -v lsof &> /dev/null; then
    if lsof -i :8080 &> /dev/null; then
        check_warning "Port 8080 is already in use"
    else
        check_passed "Port 8080 is available"
    fi
else
    check_warning "lsof not found, skipping port check"
fi

# Summary
echo ""
echo "=== Setup Summary ==="
echo ""
echo "✓ Configuration complete!"
echo ""
echo "Next steps:"
echo "1. Download Algerian OSM data:"
echo "   bash scripts/download-algeria-data.sh"
echo ""
echo "2. (Optional) Download fonts for better text rendering:"
echo "   bash scripts/download-fonts.sh"
echo ""
echo "3. Start TileServer GL:"
echo "   npm run tileserver"
echo ""
echo "4. Access the map at:"
echo "   http://localhost:8080"
echo ""
echo "5. For React Native integration, see:"
echo "   docs/REACT_NATIVE_SETUP.md"
echo ""
