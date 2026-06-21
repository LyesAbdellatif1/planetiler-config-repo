# Interactive single-POI helper
# Prompts for POI details, appends to custom-pois.geojson, optionally re-tiles

$ROOT = Split-Path $PSScriptRoot -Parent

Write-Host ""
Write-Host "Add a Custom POI" -ForegroundColor Cyan
Write-Host "----------------" -ForegroundColor Cyan

$name = Read-Host "Name"
$lat  = Read-Host "Latitude  (e.g. 36.7538)"
$lon  = Read-Host "Longitude (e.g. 3.0588)"

Write-Host ""
Write-Host "Common subclasses for transport apps:" -ForegroundColor Yellow
Write-Host "  bus_station  station  aerodrome  fuel  parking  car_rental"
Write-Host "  hospital     police   pharmacy   bank  hotel    restaurant"
Write-Host "  school       mosque   fire_station      post_office"
Write-Host ""
$subclass = Read-Host "Subclass"
$notes    = Read-Host "Notes (optional)"

# Build a temp CSV
$tmpCsv = [System.IO.Path]::GetTempFileName() -replace "\.tmp$", ".csv"
"name,lat,lon,subclass,confidence,notes" | Set-Content $tmpCsv
"`"$name`",$lat,$lon,$subclass,1.0,`"$notes`"" | Add-Content $tmpCsv

Write-Host ""
python "$ROOT\scripts\bulk-import-pois.py" --csv $tmpCsv

Remove-Item $tmpCsv -ErrorAction SilentlyContinue

Write-Host ""
$retile = Read-Host "Re-tile and restart TileServer now? (y/N)"
if ($retile -match "^[Yy]") {
    powershell -ExecutionPolicy Bypass -File "$PSScriptRoot\retile-custom.ps1"
} else {
    Write-Host "Run 'npm run retile:custom' when ready to publish." -ForegroundColor Gray
}
