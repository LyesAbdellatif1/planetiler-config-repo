# Run Planetiler via Docker to generate MBTiles from OSM data
# Requires Docker. Java is NOT needed.

$ErrorActionPreference = "Stop"

$ProjectDir  = Split-Path (Split-Path $PSCommandPath)
$DataDir     = "$ProjectDir\data"
$OsmFile     = "$DataDir\algeria-latest.osm.pbf"
$OutputFile  = "$DataDir\algeria.mbtiles"

Write-Host "=== Planetiler Tile Generation for Algeria ==="
Write-Host ""

# Pre-flight checks
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker is not installed or not in PATH. Install Docker Desktop and try again."
    exit 1
}

if (-not (Test-Path $OsmFile)) {
    Write-Error "OSM file not found: $OsmFile`nRun scripts\download-algeria-data.ps1 first."
    exit 1
}

$OsmSize = [math]::Round((Get-Item $OsmFile).Length / 1MB, 1)
Write-Host "Input:  $OsmFile ($OsmSize MB)"
Write-Host "Output: $OutputFile"
Write-Host ""

if (Test-Path $OutputFile) {
    $answer = Read-Host "algeria.mbtiles already exists. Overwrite? (y/N)"
    if ($answer -notmatch '^[Yy]') {
        Write-Host "Aborted."
        exit 0
    }
}

# Docker requires forward-slash paths for volume mounts
$DataDirDocker = $DataDir -replace '\\', '/' -replace '^([A-Za-z]):', '/$1'

Write-Host "Pulling Planetiler Docker image..."
docker pull ghcr.io/onthegomap/planetiler:latest

Write-Host ""
Write-Host "Starting Planetiler processing (this takes several minutes)..."
Write-Host ""

docker run --rm `
    -v "${DataDirDocker}:/data" `
    -e JAVA_TOOL_OPTIONS="-Xmx6g" `
    ghcr.io/onthegomap/planetiler:latest `
    --osm-path=/data/algeria-latest.osm.pbf `
    --output=/data/algeria.mbtiles `
    --bounds=2.0,18.0,9.0,37.0 `
    --minzoom=0 `
    --maxzoom=14 `
    --download `
    --download-threads=4 `
    --nodemap-type=array `
    --storage=mmap

if ($LASTEXITCODE -eq 0 -and (Test-Path $OutputFile)) {
    $SizeMB = [math]::Round((Get-Item $OutputFile).Length / 1MB, 1)
    Write-Host ""
    Write-Host "=== Success ==="
    Write-Host "Generated: $OutputFile ($SizeMB MB)"
    Write-Host ""
    Write-Host "Next steps:"
    Write-Host "  1. Start TileServer GL:  docker-compose up"
    Write-Host "  2. Open:                 http://localhost:8080"
} else {
    Write-Error "Planetiler failed with exit code $LASTEXITCODE"
    exit 1
}