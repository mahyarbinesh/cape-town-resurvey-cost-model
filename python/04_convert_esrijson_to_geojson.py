import json
from pathlib import Path


def convert_esri_to_geojson(esri_path, geojson_path):
    with open(esri_path, "r", encoding="utf-8") as f:
        esri_data = json.load(f)

    geojson_features = []

    for feature in esri_data["features"]:
        geometry = feature.get("geometry")
        attributes = feature.get("attributes", {})

        # Convert geometry
        if geometry and "rings" in geometry:
            geojson_geom = {
                "type": "Polygon",
                "coordinates": geometry["rings"]
            }
        else:
            continue  # skip invalid geometry

        # Create GeoJSON feature
        geojson_features.append({
            "type": "Feature",
            "geometry": geojson_geom,
            "properties": attributes
        })

    # Full GeoJSON structure
    geojson_data = {
        "type": "FeatureCollection",
        "features": geojson_features
    }

    # Save to file
    with open(geojson_path, "w", encoding="utf-8") as f:
        json.dump(geojson_data, f)

    print(f"✅ Converted and saved: {geojson_path}")


# === CONFIGURATION ===

input_folder = Path(
    "C:/Users/mahya/OneDrive - TUM/4. Thesis/Data/building/"
    "building_low_detail_chunks"
)

output_folder = input_folder / "converted_geojson"
output_folder.mkdir(exist_ok=True)

# Convert all files

for i in range(1, 30):  # Parts 1 to 29
    in_file = input_folder / (
        f"building_low_detail_esrijson_part_{i:05}.json"
    )
    out_file = output_folder / f"part_{i:05}.geojson"

    if in_file.exists():
        convert_esri_to_geojson(in_file, out_file)
    else:
        print(f"⚠️ File not found: {in_file}")
