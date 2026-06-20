"""
Decode POI layer from algeria.mbtiles using mapbox_vector_tile.
Samples zoom-14 tiles across Algeria to build a full subclass inventory.
"""
import sqlite3, gzip, sys, math
from collections import Counter, defaultdict

def lng_lat_to_tile(lng, lat, z):
    n = 2 ** z
    x = int((lng + 180.0) / 360.0 * n)
    lat_rad = math.radians(lat)
    y = int((1.0 - math.log(math.tan(lat_rad) + 1.0 / math.cos(lat_rad)) / math.pi) / 2.0 * n)
    return x, y

def main():
    import mapbox_vector_tile

    db_path = sys.argv[1] if len(sys.argv) > 1 else '/data/algeria.mbtiles'
    conn = sqlite3.connect(db_path)

    # Check what layers and zoom levels exist
    meta = dict(conn.execute('SELECT name, value FROM metadata').fetchall())
    print(f"MBTiles: {meta.get('name','?')}", flush=True)
    print(f"Bounds: {meta.get('bounds','?')}", flush=True)
    print(f"Minzoom: {meta.get('minzoom','?')}  Maxzoom: {meta.get('maxzoom','?')}", flush=True)

    zoom_counts = dict(conn.execute(
        'SELECT zoom_level, COUNT(*) FROM tiles GROUP BY zoom_level'
    ).fetchall())
    print(f"Tile counts by zoom: {zoom_counts}", flush=True)

    # Sample tiles at zoom 14 across populated Algeria
    z = 14
    sample_points = [
        (36.73, 3.06),   # Algiers center
        (36.70, 3.10),   # Algiers east
        (36.76, 3.00),   # Algiers west
        (36.37, 6.61),   # Constantine
        (35.69, 0.63),   # Tiaret
        (35.56, -0.63),  # Oran
        (36.46, 2.82),   # Blida
        (36.19, 1.33),   # Medea
        (36.73, 5.08),   # Bejaia
        (36.90, 7.75),   # Annaba
        (35.19, 6.17),   # Batna
        (34.85, 5.73),   # Biskra
        (36.60, 4.05),   # Tizi Ouzou
        (35.33, 2.89),   # M'Sila
        (36.27, 6.08),   # Setif
        (36.82, 7.36),   # Skikda
        (35.68, 2.89),   # Bou Saada
        (36.74, 3.08),   # Algiers grid 2
        (36.72, 3.04),   # Algiers grid 3
        (36.71, 3.07),   # Algiers grid 4
    ]

    subclass_counts = Counter()
    class_counts = Counter()
    class_sub = defaultdict(Counter)
    tiles_sampled = 0
    all_layer_names = set()

    print(f"\nSampling {len(sample_points)} tiles at zoom {z}...", flush=True)

    for lat, lng in sample_points:
        x, y = lng_lat_to_tile(lng, lat, z)
        tms_y = (2**z - 1) - y

        row = conn.execute(
            'SELECT tile_data FROM tiles WHERE zoom_level=? AND tile_column=? AND tile_row=?',
            (z, x, tms_y)
        ).fetchone()

        if not row:
            continue

        tiles_sampled += 1
        try:
            tile_data = gzip.decompress(row[0])
        except Exception:
            tile_data = row[0]

        try:
            tile = mapbox_vector_tile.decode(tile_data)
        except Exception as e:
            print(f"  Decode error at ({x},{tms_y}): {e}", flush=True)
            continue

        all_layer_names.update(tile.keys())

        poi = tile.get('poi', {})
        for feat in poi.get('features', []):
            props = feat.get('properties', {})
            cls = props.get('class', '') or ''
            sub = props.get('subclass', '') or ''
            if cls:
                class_counts[cls] += 1
            if sub:
                subclass_counts[sub] += 1
            if cls and sub:
                class_sub[cls][sub] += 1

    conn.close()

    print(f"\nTiles sampled: {tiles_sampled}/{len(sample_points)}")
    print(f"Layer names found: {sorted(all_layer_names)}")

    print(f"\n{'='*60}")
    print("OSM POI SUBCLASSES (sorted by count)")
    print(f"{'COUNT':>6}  {'SUBCLASS':<35} CLASS")
    print("-" * 60)
    for sub, cnt in subclass_counts.most_common():
        cls = max(class_sub.items(), key=lambda kv: kv[1].get(sub, 0))[0] if class_sub else ''
        print(f"{cnt:6d}  {sub:<35} {cls}")

    print(f"\n{'='*60}")
    print("OSM POI CLASSES (sorted by count)")
    for cls, cnt in class_counts.most_common():
        print(f"{cnt:6d}  {cls}")

if __name__ == '__main__':
    main()
