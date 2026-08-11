# Cape Town Cadastral Resurvey Cost Model

A PostGIS-based cadastral resurvey cost model developed as part of the master's thesis:

**Cartographic Modeling of Cadastral Resurvey Effort and Cost: A Case Study in Cape Town, South Africa**

The study developed a spatial model for estimating the relative difficulty and cost of cadastral resurveys in Cape Town. The model integrates cadastral geometry, survey age, terrain and vegetation characteristics, and accessibility to Town Survey Marks (TSMs).

## Thesis

The full master's thesis is available in the `thesis/` directory.

## Workflow

The project combined relational spatial processing with graph-based representation:

1. **Cadastral data preparation**
   - Cleaning and validation of parcel geometries
   - Coordinate transformation and spatial processing
   - Extraction of parcel geometry and related cadastral attributes

2. **Large cadastral text-data processing**
   - AWK was used to filter the large Surveyor-General parcel dataset.
   - Python/Pandas was used for subsequent enrichment and joining of cadastral information.
   - Allotment codes and names, SG years, and Survey Record information were incorporated into the processed dataset.

3. **PostGIS spatial modelling**
   - Parcel geometry and spatial attributes were processed in PostgreSQL/PostGIS.
   - Cadastral blocks were generated from parcel geometries.
   - Terrain, vegetation, survey-age and TSM accessibility factors were incorporated into the cost model.

4. **Neo4j graph representation**
   - Parcels, blocks, allotments, beacons and Town Survey Marks were represented as graph entities.
   - Relationships were created between these entities to represent cadastral structure and spatial/control relationships.
   - Cypher queries were used to inspect and validate the resulting graph.

## Repository Structure

```text
.
├── README.md
├── awk/
│   └── filter_data.awk
├── bash/
│   └── 01_run_slope_chunks.sh
├── postgis/
│   ├── 01_parcel_cleaning.sql
│   ├── 02_simplification_vertex_count.sql
│   ├── 03_beacon_generation.sql
│   └── 04_block_generation_and_assignment.sql
├── python/
│   ├── 01_add_region_names.py
│   ├── 02_prepare_allotment_codes.py
│   ├── 03_check_duplicates.py
│   ├── 04_convert_esrijson_to_geojson.py
│   └── 05_filter_and_enrich_data.py
└── neo4j/
    ├── 01_import_parcels.cypher
    ├── 02_parcel_beacon_relationships.cypher
    ├── 02b_split_beacon_relationships.ps1
    ├── 03_import_blocks.cypher
    ├── 04_parcel_block_relationships.cypher
    ├── 05_allotment_nodes_and_relationships.cypher
    ├── 06_import_tsm.cypher
    ├── 07_parcel_tsm_relationships.cypher
    └── 08_graph_queries.cypher
