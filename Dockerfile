FROM node:18-alpine

WORKDIR /app

# Install TileServer GL globally
RUN npm install -g @mapbox/tileserver-gl-cli

# Install curl for health checks
RUN apk add --no-cache curl

# Copy configuration files
COPY tileserver-gl-config.json ./
COPY osm-bright-style.json ./

# Copy data directory with tiles and fonts
COPY data ./data

# Expose TileServer GL port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/data || exit 1

# Start TileServer GL
CMD ["tileserver-gl", "--config", "tileserver-gl-config.json", "--port", "8080"]
