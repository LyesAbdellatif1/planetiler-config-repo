"""
Bulk-import custom POIs from a CSV file into the custom layer GeoJSON.

Usage:
    python scripts/bulk-import-pois.py --csv my-pois.csv [--retile] [--no-backup]

CSV must have these columns (header row required):
    name, lat, lon, subclass

Optional columns:
    confidence   float 0-1 (default: 1.0)
    notes        free-text, stored in properties for reference

Output: data/custom-pois.geojson
Re-tile: run `npm run retile:custom` (or pass --retile)
"""

import argparse
import csv
import json
import os
import shutil
import subprocess
import sys
from datetime import datetime

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GEOJSON_PATH = os.path.join(ROOT, "data", "custom-pois.geojson")

# All valid OMT subclass values (derived from flatten-overture.py CATEGORY_MAP)
VALID_SUBCLASSES = {
    "aerodrome", "amusement_ride", "aquarium", "atm", "attraction",
    "bakery", "bank", "bar", "bicycle", "bus_station", "butcher",
    "cafe", "camp_site", "car_rental", "car_repair", "castle",
    "church", "cinema", "clothes", "college", "convenience",
    "dentist", "doctors", "embassy",
    "fast_food", "ferry_terminal", "fire_station", "florist", "fuel", "furniture",
    "gallery", "garden", "golf_course", "grocery",
    "hairdresser", "hospital", "hostel", "hotel",
    "ice_cream",
    "jewelry", "kindergarten",
    "laundry", "library", "lighthouse",
    "marina", "monument", "mosque", "museum",
    "office",
    "park", "parking", "pharmacy", "pitch", "place_of_worship", "playground",
    "police", "post_office", "prison",
    "restaurant",
    "school", "shoes", "shop", "sports_centre", "stadium", "station", "subway", "supermarket",
    "swimming", "synagogue",
    "theatre", "town_hall",
    "veterinary",
    "zoo",
}

# Algeria bounding box (with small margin)
BOUNDS = {"lon_min": -2.0, "lon_max": 12.0, "lat_min": 17.0, "lat_max": 38.0}


def load_geojson(path):
    if not os.path.exists(path):
        return {"type": "FeatureCollection", "features": []}
    with open(path, encoding="utf-8") as f:
        return json.load(f)


def make_dedup_key(name, lat, lon):
    return f"{name.strip().lower()}|{round(float(lat), 5)}|{round(float(lon), 5)}"


def existing_keys(geojson):
    keys = set()
    for feat in geojson.get("features", []):
        p = feat.get("properties", {})
        coords = feat.get("geometry", {}).get("coordinates", [None, None])
        key = make_dedup_key(p.get("name", ""), coords[1], coords[0])
        keys.add(key)
    return keys


def backup(path):
    ts = datetime.now().strftime("%Y%m%d-%H%M%S")
    bak = f"{path}.bak-{ts}"
    shutil.copy2(path, bak)
    return bak


def parse_row(row, line_num):
    errors = []

    name = row.get("name", "").strip()
    if not name:
        errors.append("missing name")

    try:
        lat = float(row["lat"])
    except (KeyError, ValueError):
        lat = None
        errors.append("invalid lat")

    try:
        lon = float(row["lon"])
    except (KeyError, ValueError):
        lon = None
        errors.append("invalid lon")

    subclass = row.get("subclass", "").strip().lower()
    if not subclass:
        errors.append("missing subclass")
    elif subclass not in VALID_SUBCLASSES:
        errors.append(f"unknown subclass '{subclass}' (see docs/POI_MANAGEMENT.md for valid values)")

    if lat is not None and not (BOUNDS["lat_min"] <= lat <= BOUNDS["lat_max"]):
        errors.append(f"lat {lat} outside Algeria bounds ({BOUNDS['lat_min']}–{BOUNDS['lat_max']})")

    if lon is not None and not (BOUNDS["lon_min"] <= lon <= BOUNDS["lon_max"]):
        errors.append(f"lon {lon} outside Algeria bounds ({BOUNDS['lon_min']}–{BOUNDS['lon_max']})")

    try:
        confidence = float(row.get("confidence", 1.0))
        if not 0.0 <= confidence <= 1.0:
            errors.append(f"confidence {confidence} must be 0–1")
    except ValueError:
        confidence = 1.0

    if errors:
        return None, f"Row {line_num}: {'; '.join(errors)}"

    props = {
        "name": name,
        "subclass": subclass,
        "confidence": round(confidence, 3),
        "source": "custom",
    }
    notes = row.get("notes", "").strip()
    if notes:
        props["notes"] = notes

    feature = {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [lon, lat]},
        "properties": props,
    }
    return feature, None


def main():
    parser = argparse.ArgumentParser(description="Import POIs from CSV into custom-pois.geojson")
    parser.add_argument("--csv", required=True, help="Path to input CSV file")
    parser.add_argument("--retile", action="store_true", help="Re-run tippecanoe and restart TileServer after import")
    parser.add_argument("--no-backup", action="store_true", help="Skip backup of existing GeoJSON")
    parser.add_argument("--output", default=GEOJSON_PATH, help=f"Output GeoJSON path (default: {GEOJSON_PATH})")
    args = parser.parse_args()

    if not os.path.exists(args.csv):
        print(f"ERROR: CSV file not found: {args.csv}", file=sys.stderr)
        sys.exit(1)

    geojson = load_geojson(args.output)
    existing = existing_keys(geojson)
    initial_count = len(geojson["features"])

    added = []
    skipped_dupes = []
    rejected = []

    with open(args.csv, newline="", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        if not reader.fieldnames:
            print("ERROR: CSV file is empty or has no header row", file=sys.stderr)
            sys.exit(1)

        missing = {"name", "lat", "lon", "subclass"} - set(reader.fieldnames)
        if missing:
            print(f"ERROR: CSV missing required columns: {', '.join(sorted(missing))}", file=sys.stderr)
            print(f"       Found columns: {', '.join(reader.fieldnames)}", file=sys.stderr)
            sys.exit(1)

        for i, row in enumerate(reader, start=2):
            feature, error = parse_row(row, i)
            if error:
                rejected.append(error)
                continue

            key = make_dedup_key(
                feature["properties"]["name"],
                feature["geometry"]["coordinates"][1],
                feature["geometry"]["coordinates"][0],
            )
            if key in existing:
                skipped_dupes.append(feature["properties"]["name"])
                continue

            existing.add(key)
            added.append(feature)
            geojson["features"].append(feature)

    print(f"\nImport summary:")
    print(f"  Existing POIs : {initial_count}")
    print(f"  Added         : {len(added)}")
    print(f"  Skipped (dupes): {len(skipped_dupes)}")
    print(f"  Rejected      : {len(rejected)}")

    if rejected:
        print("\nRejected rows:")
        for r in rejected:
            print(f"  - {r}")

    if added:
        if not args.no_backup and os.path.exists(args.output):
            bak = backup(args.output)
            print(f"\nBackup created: {bak}")

        os.makedirs(os.path.dirname(args.output), exist_ok=True)
        with open(args.output, "w", encoding="utf-8") as f:
            json.dump(geojson, f, ensure_ascii=False, separators=(",", ":"))
            f.write("\n")
        print(f"Written: {args.output}  ({len(geojson['features'])} total features)")

        if args.retile:
            retile_script = os.path.join(ROOT, "scripts", "retile-custom.ps1")
            print("\nRunning retile-custom.ps1 ...")
            subprocess.run(
                ["powershell", "-ExecutionPolicy", "Bypass", "-File", retile_script],
                check=True,
            )
    else:
        print("\nNothing to write — no new POIs were valid and non-duplicate.")
        if rejected and not added:
            sys.exit(1)


if __name__ == "__main__":
    main()
