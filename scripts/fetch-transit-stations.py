#!/usr/bin/env python3
"""Fetch Algeria metro (subway) and tram stations from OpenStreetMap (Overpass API)
and write them to data/transit-stations.geojson.

The OSM data already carries the real station names (and exact coordinates) that the
local planetiler-built base tiles are missing. This script pulls them straight from
Overpass so they can be tiled (scripts/retile-transit.ps1) into a dedicated `transit`
source and rendered by the tr_metro / tr_tram style layers.

Idempotent: fully overwrites data/transit-stations.geojson on each run (a timestamped
backup of any existing file is kept). Do NOT hand-edit the output — re-run this instead.

Stdlib only; intended to run inside python:3.11-slim via scripts/fetch-transit-stations.ps1.
"""

import json
import os
import shutil
import sys
import urllib.request
import urllib.error
import urllib.parse
from datetime import datetime

# Project root = parent of this script's directory
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "data", "transit-stations.geojson")

OVERPASS_ENDPOINTS = [
    "https://overpass-api.de/api/interpreter",
    "https://overpass.kumi.systems/api/interpreter",
]

# Pulls every Algeria metro (subway), tram, bus-station and bus-stop node.
OVERPASS_QUERY = """
[out:json][timeout:120];
area["ISO3166-1"="DZ"]->.a;
(
  node["railway"="tram_stop"](area.a);
  node["station"="subway"](area.a);
  node["railway"="station"]["station"="subway"](area.a);
  node["amenity"="bus_station"](area.a);
  node["highway"="bus_stop"](area.a);
  node["aerialway"="station"](area.a);
  way["aerialway"="station"](area.a);
);
out center;
"""


def fetch_overpass():
    """POST the query to Overpass, trying each endpoint until one succeeds."""
    data = urllib.parse.urlencode({"data": OVERPASS_QUERY}).encode("utf-8")
    last_err = None
    for url in OVERPASS_ENDPOINTS:
        try:
            print(f"Querying Overpass: {url} ...", flush=True)
            req = urllib.request.Request(
                url, data=data, headers={"User-Agent": "algeria-transit-map/1.0"}
            )
            with urllib.request.urlopen(req, timeout=120) as resp:
                return json.loads(resp.read().decode("utf-8"))
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as e:
            print(f"  endpoint failed: {e}", flush=True)
            last_err = e
    raise RuntimeError(f"All Overpass endpoints failed. Last error: {last_err}")


def classify(tags):
    """Map OSM tags to a single transit mode, or None if it isn't one we render."""
    if tags.get("station") == "subway":
        return "metro"
    if tags.get("railway") == "tram_stop":
        return "tram"
    if tags.get("amenity") == "bus_station":
        return "bus_station"
    if tags.get("highway") == "bus_stop":
        return "bus"
    if tags.get("aerialway") == "station":
        return "aerialway"
    return None


def to_feature(el):
    """Convert one Overpass node/way into a GeoJSON Point feature, or None if not relevant."""
    t = el.get("type")
    if t == "node":
        lon, lat = el.get("lon"), el.get("lat")
    elif t == "way":
        # ways (e.g. aerialway station buildings) carry geometry via `out center`
        center = el.get("center") or {}
        lon, lat = center.get("lon"), center.get("lat")
    else:
        return None
    if lon is None or lat is None:
        return None

    tags = el.get("tags", {})

    mode = classify(tags)
    if mode is None:
        return None

    props = {"mode": mode, "source": "osm-transit", "osm_id": el.get("id")}
    # Keep name + localized variants; omit absent keys so the style coalesce works cleanly.
    if tags.get("name"):
        props["name"] = tags["name"]
    if tags.get("name:fr"):
        props["name_fr"] = tags["name:fr"]
    if tags.get("name:ar"):
        props["name_ar"] = tags["name:ar"]

    return {
        "type": "Feature",
        "geometry": {"type": "Point", "coordinates": [lon, lat]},
        "properties": props,
    }


def main():
    result = fetch_overpass()
    elements = result.get("elements", [])

    features = []
    for el in elements:
        f = to_feature(el)
        if f is not None:
            features.append(f)

    def count(mode):
        return sum(1 for f in features if f["properties"]["mode"] == mode)

    n_total = len(features)
    by_mode = {m: count(m) for m in ("metro", "tram", "bus_station", "bus", "aerialway")}
    n_named = sum(
        1
        for f in features
        if any(k in f["properties"] for k in ("name", "name_fr", "name_ar"))
    )

    if n_total == 0:
        print("ERROR: Overpass returned 0 stations. Aborting (output not written).")
        sys.exit(1)

    # Backup an existing output before overwriting.
    if os.path.exists(OUT):
        ts = datetime.now().strftime("%Y%m%d-%H%M%S")
        bak = f"{OUT}.bak-{ts}"
        shutil.copy2(OUT, bak)
        print(f"Backup: {bak}")

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    fc = {"type": "FeatureCollection", "features": features}
    with open(OUT, "w", encoding="utf-8") as fh:
        json.dump(fc, fh, ensure_ascii=False, indent=1)

    print(f"Wrote {OUT}")
    print(
        f"  total: {n_total}  (metro: {by_mode['metro']}, tram: {by_mode['tram']}, "
        f"bus_station: {by_mode['bus_station']}, bus_stop: {by_mode['bus']}, "
        f"aerialway: {by_mode['aerialway']})"
    )
    print(f"  with a name:    {n_named}  (unnamed: {n_total - n_named})")
    print("Next: npm run retile:transit")


if __name__ == "__main__":
    main()
