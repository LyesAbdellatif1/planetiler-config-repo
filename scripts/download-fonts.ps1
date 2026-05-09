# Download OpenMapTiles Fonts for text rendering
# PowerShell equivalent of download-fonts.sh

$ErrorActionPreference = "Stop"

$ProjectDir = Split-Path (Split-Path $PSCommandPath)
$FontsDir   = "$ProjectDir\data\fonts"
$ZipPath    = "$FontsDir\fonts.zip"

# noto-open-sans.zip includes both Open Sans and Noto Sans (required by osm-liberty style)
$FontsUrl = "https://github.com/openmaptiles/fonts/releases/download/v2.0/noto-open-sans.zip"

Write-Host "=== OpenMapTiles Fonts Download ==="
Write-Host "Downloading fonts for TileServer GL..."
Write-Host ""

New-Item -ItemType Directory -Force -Path $FontsDir | Out-Null

if (Get-ChildItem $FontsDir -Filter "*.pbf" -Recurse -ErrorAction SilentlyContinue) {
    Write-Host "Fonts already exist, skipping download."
} else {
    Write-Host "Downloading fonts package (~64 MB, this may take a few minutes)..."
    try {
        Invoke-WebRequest -Uri $FontsUrl -OutFile $ZipPath -UseBasicParsing
        Write-Host "Downloaded fonts.zip"
    } catch {
        Write-Warning "Could not download fonts: $_"
        Write-Host "TileServer GL will use system fonts as fallback."
        exit 0
    }

    Write-Host "Extracting fonts..."
    Expand-Archive -Path $ZipPath -DestinationPath $FontsDir -Force
    Remove-Item $ZipPath
    Write-Host "Fonts extracted"
}

$FontCount = (Get-ChildItem $FontsDir -Filter "*.pbf" -Recurse).Count

Write-Host ""
Write-Host "=== Download Summary ==="
Write-Host "Font files ready in: data\fonts\"
Write-Host "  Total font files: $FontCount"
Write-Host ""
Write-Host "These fonts include:"
Write-Host "  - Open Sans (Regular, Bold, Italic, etc.)"
Write-Host "  - Noto Sans (multilingual support)"
Write-Host ""
Write-Host "TileServer GL serves fonts at: http://localhost:8080/fonts/{fontstack}/{range}.pbf"