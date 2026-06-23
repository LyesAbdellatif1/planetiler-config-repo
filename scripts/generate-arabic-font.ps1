# Generate Noto Sans Arabic glyph PBFs into data/fonts so Arabic labels render.
#
# The bundled fonts (Open Sans) have NO Arabic glyphs, so any Arabic-script label
# (many tram/metro/bus station names) rendered blank. This downloads Noto Sans Arabic
# and converts it to MapLibre glyph ranges via node-fontnik (in Docker).
#
# Run once (re-run only if you change/upgrade the Arabic font):
#   npm run fonts:arabic
#
# After it finishes, restart TileServer: docker compose restart tileserver

$ROOT = Split-Path $PSScriptRoot -Parent
$SRC  = "$ROOT\data\fonts-src"
$TTF  = "$SRC\NotoSansArabic.ttf"
$OUT  = "$ROOT\data\fonts\Noto Sans Arabic"

New-Item -ItemType Directory -Force $SRC | Out-Null

if (-not (Test-Path $TTF) -or (Get-Item $TTF).Length -lt 50000) {
    Write-Host "Downloading Noto Sans Arabic ..." -ForegroundColor Cyan
    $url = "https://github.com/google/fonts/raw/main/ofl/notosansarabic/NotoSansArabic%5Bwdth%2Cwght%5D.ttf"
    Invoke-WebRequest -Uri $url -OutFile $TTF -UseBasicParsing
}
Write-Host "TTF: $TTF ($((Get-Item $TTF).Length) bytes)" -ForegroundColor Gray

# Docker path for the repo root (PS 5.1 compatible)
$drive = $ROOT[0].ToString().ToLower()
$dockerRoot = $drive + ":" + ($ROOT.Substring(2) -replace "\\", "/")

# fontnik is installed in a throwaway /build dir because this repo's package.json
# has a dependency that fails `npm install` in-tree; NODE_PATH points node at it.
Write-Host "Generating glyph ranges via node-fontnik (Docker) ..." -ForegroundColor Cyan
docker run --rm -v "${dockerRoot}:/w" node:18 bash -c "mkdir -p /build && cd /build && npm init -y >/dev/null 2>&1 && npm install fontnik >/dev/null 2>&1 && cd /w && NODE_PATH=/build/node_modules node scripts/_genfont.cjs 'data/fonts-src/NotoSansArabic.ttf' 'data/fonts/Noto Sans Arabic'"

if ($LASTEXITCODE -ne 0) {
    Write-Host "Glyph generation failed (exit $LASTEXITCODE)" -ForegroundColor Red
    exit $LASTEXITCODE
}

$count = (Get-ChildItem -LiteralPath $OUT -Filter *.pbf -ErrorAction SilentlyContinue).Count
Write-Host "Done: $count glyph ranges in '$OUT'" -ForegroundColor Green
Write-Host "Now restart TileServer:  docker compose restart tileserver" -ForegroundColor Yellow
