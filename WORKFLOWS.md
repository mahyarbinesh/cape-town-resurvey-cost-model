# Thesis Technical Workflows

This document summarises the main technical workflows developed during the master's thesis.

The repository contains selected code examples from these workflows. The workflows themselves involved multiple stages, intermediate datasets, database tables, and processing approaches; therefore, the examples in the repository are not intended to form one standalone, fully reproducible software package.

---

## 1. Large Surveyor-General Dataset Processing

The Surveyor-General parcel and survey-record data were initially available as large text datasets.

Because the datasets contained hundreds of thousands of records, a combination of AWK, Python/Pandas and PostgreSQL/PostGIS was used rather than relying on GIS desktop joins for the complete dataset.

### Workflow

Surveyor-General parcel text data  
→ Extract relevant allotment codes  
→ AWK filtering of large SG dataset  
→ Intermediate filtered CSV  
→ Python/Pandas enrichment  
→ Allotment names + SG years  
→ Survey Record (SR) integration  
→ Final enriched SG/SR dataset  
→ PostgreSQL/PostGIS

AWK was used to filter the large SG dataset using the first eight characters of the parcel identifier as the allotment code.

Python/Pandas was then used to:
- prepare and check allotment codes;
- remove duplicate allotment lookup records;
- join allotment names;
- extract SG years;
- integrate Survey Record data;
- remove duplicate `UniqueIdNumber` records before merging;
- extract SR years.

The final enrichment workflow retained 949,474 filtered records.

**Example code:**
- `awk/filter_data.awk`
- `python/02_prepare_allotment_codes.py`
- `python/03_check_duplicates.py`
- `python/01_add_region_names.py`
- `python/05_filter_and_enrich_data.py`

---

## 2. Cadastral Data Preparation in PostGIS

The cadastral dataset contained a very large number of polygon features, making direct desktop GIS processing inefficient.

PostgreSQL with PostGIS was therefore used as the main spatial database environment.

### Workflow

Cadastral polygon dataset  
→ PostGIS import  
→ Geometry validation  
→ 2D geometry standardisation  
→ Polygon / MultiPolygon extraction  
→ UTM Zone 34S transformation  
→ Area and perimeter calculation  
→ Spatial indexing  
→ Cadastral analysis tables

Geometry preparation included `ST_Force2D()`, `ST_MakeValid()`, `ST_CollectionExtract()`, `ST_Multi()` and `ST_Transform()`.

The analysis was carried out in UTM Zone 34S (EPSG:32734), allowing distances and areas to be calculated in metres.

**Example code:**
- `postgis/01_parcel_cleaning.sql`

---

## 3. Parcel Geometry Simplification and Complexity

Parcel geometry was simplified while preserving topology to reduce unnecessary geometric complexity during subsequent spatial processing.

The number of polygon vertices was also used as a measure of geometric complexity.

### Workflow

Clean parcel geometry  
→ Topology-preserving simplification  
→ Vertex counting  
→ Parcel geometric complexity  
→ Sides-based cost factor

The thesis used parcel side/vertex complexity as one of the cost-model factors.

**Example code:**
- `postgis/02_simplification_vertex_count.sql`

---

## 4. Beacon Generation

Parcel vertices were processed to identify common physical survey points, referred to in the graph model as beacons.

### Workflow

Parcel vertices  
→ Vertex extraction  
→ Spatial clustering / deduplication  
→ Global beacon points  
→ Parcel–beacon relationships

The resulting beacon structure allowed a physical point shared by multiple parcels to be represented once and linked to the relevant parcels.

The resulting parcel–beacon relationships were later used in the graph representation.

**Example code:**
- `postgis/03_beacon_generation.sql`
- `neo4j/02_parcel_beacon_relationships.cypher`

---

## 5. Cadastral Block Generation

Cadastral blocks were derived from parcel geometries using spatial processing.

### Workflow

Parcel polygons  
→ Buffer  
→ Union / dissolve  
→ Boundary restoration  
→ Hole removal / geometry cleaning  
→ Overlap checks  
→ Final block polygons  
→ Parcel-to-block assignment

Block assignment used spatial relationships and intersection areas to associate parcels with the appropriate block.

The resulting blocks were used for higher-level aggregation of resurvey cost.

**Example code:**
- `postgis/04_block_generation_and_assignment.sql`

---

## 6. Terrain and Raster Processing

Terrain information was derived from a 5 m digital elevation model.

Slope was calculated and then used to derive parcel-level terrain metrics.

### Workflow

5 m DEM  
→ Slope raster  
→ PostGIS raster storage  
→ Parcel/raster spatial intersection  
→ Raster clipping  
→ Parcel-level statistics  
→ Mean slope and related metrics  
→ Terrain difficulty classification

PostGIS raster functions such as `ST_Slope()`, `ST_Clip()` and `ST_SummaryStats()` were used during the raster workflow.

Large parcel-level raster calculations were processed in batches to make the workflow manageable.

The final model used parcel-level mean slope in degrees.

**Example workflow:**
- `bash/01_run_slope_chunks.sh`

---

## 7. Vegetation and Canopy Analysis

Tree canopy data were incorporated to represent vegetation-related field difficulty.

### Workflow

Tree canopy data  
→ Spatial overlay with parcels  
→ Canopy coverage calculation  
→ Parcel-level canopy percentage  
→ Vegetation classification  
→ Combined terrain–vegetation difficulty

Canopy coverage was classified into five categories:

- Open: 0–5%
- Light: 5–25%
- Moderate: 25–50%
- Heavy: 50–75%
- Jungle: ≥75%

Slope and canopy classes were then combined using the topography–vegetation difficulty matrix used in the thesis.

---

## 8. Survey Age and SG/SR Integration

Survey age was incorporated using information extracted from the cadastral and Survey Record datasets.

### Workflow

SG / SR identifiers  
→ Extract SG year  
→ Extract SR year where available  
→ Link records to parcels  
→ Determine parcel survey-age information  
→ Age-related cost factor

Where survey-record information was unavailable, the workflow used the available SG year information according to the modelling approach described in the thesis.

The age factor was one of the components of the final parcel-level cost model.

---

## 9. Town Survey Mark (TSM) Accessibility

TSM accessibility was developed at two levels during the project.

### Initial spatial proximity workflow

A nearest-TSM calculation was first implemented using spatial proximity between parcels and active TSMs.

This produced parcel-level TSM identifiers and distances.

### Network-based workflow

A more detailed road-network approach was subsequently developed.

Road network  
→ Routable graph  
→ Parcel → road access  
→ TSM status classification  
→ TSM → nearest road edge  
→ TSM → road-network entry node  
→ Virtual TSM network connections  
→ pgRouting  
→ Nearest TSM  
→ Second-nearest TSM  
→ Parcel-level network distances

The workflow used a road graph consisting of nodes and edges and incorporated parcel access links.

TSMs were snapped to the road network using their nearest road edge and an appropriate network entry node.

A virtual super-node was used to connect active TSMs to the routing graph.

The nearest and second-nearest TSMs were then determined using network routing. Spatial pruning and batching were used for the more expensive second-nearest calculations.

The final parcel-level result contained the nearest and second-nearest TSM identifiers and their total network distances.

The workflow also included connected-component checks to identify parcels for which a second reachable TSM was not available.

---

## 10. Cost Model Construction

The processed parcel-level indicators were combined into the cadastral resurvey cost model.

### Main factors

Base Gazette tariff  
+ Parcel geometric complexity  
+ Terrain–vegetation difficulty  
+ Parcel age  
+ TSM accessibility  
→ Composite parcel cost

The model used the 2003 Gazette tariff as the baseline and applied the modelled uplift factors to produce a unitised parcel-level resurvey cost.

The environmental factor was derived from the slope–vegetation matrix, while geometric complexity, age and TSM accessibility contributed additional adjustments.

The resulting cost values were then used for spatial analysis and aggregation.

---

## 11. Parcel, Block and Allotment Aggregation

The parcel-level results were aggregated to higher cadastral units.

### Workflow

Parcel-level cost  
→ Cadastral blocks  
→ Allotment townships  
→ Mean / summary cost indicators  
→ Spatial comparison and mapping

This allowed the model to be examined at parcel, block and allotment levels.

The final thesis reported parcel-level results for 795,344 analytical parcels and subsequently aggregated these results to cadastral blocks and allotment areas.

---

## 12. Neo4j Graph Representation

A graph representation was developed to complement the relational PostGIS database.

The graph model represented cadastral entities including:

- Allotment
- Block
- Parcel
- Beacon
- TSM

### Workflow

PostGIS processed datasets  
→ CSV exports  
→ Neo4j node imports  
→ Parcel / Block / Allotment / Beacon / TSM nodes  
→ Relationships  
→ Cypher queries  
→ Graph inspection and validation

Relationships represented cadastral structure and proximity/control relationships between the entities.

Example relationship types included:

- Parcel → Beacon
- Parcel → Block
- Parcel → Allotment
- Parcel → TSM

Cypher queries were used to inspect the resulting graph structure.

**Example code:**
- `neo4j/01_import_parcels.cypher`
- `neo4j/02_parcel_beacon_relationships.cypher`
- `neo4j/03_import_blocks.cypher`
- `neo4j/04_parcel_block_relationships.cypher`
- `neo4j/05_allotment_nodes_and_relationships.cypher`
- `neo4j/06_import_tsm.cypher`
- `neo4j/07_parcel_tsm_relationships.cypher`
- `neo4j/08_graph_queries.cypher`

---

## 13. Large-File and Batch Processing

Several stages of the project required processing datasets too large for convenient single-step desktop workflows.

Different strategies were used depending on the data and operation:

- AWK for streaming text-file filtering;
- Pandas chunk processing;
- PowerShell for splitting large CSV files;
- Bash loops for chunked spatial processing;
- PostgreSQL/PostGIS batch processing;
- database indexes and materialised results for expensive spatial/network operations.

These approaches were used to make large-scale processing practical while retaining the spatial database as the main analytical environment.

---

## 14. Data Validation and Quality Control

Validation was performed throughout the workflow rather than only at the end.

Examples included:

- checking invalid and empty geometries;
- checking geometry types and dimensions;
- checking duplicate identifiers;
- checking parcel/block overlaps;
- checking raster-derived values and distributions;
- checking missing raster intersections;
- checking TSM network connectivity;
- checking parcels without a second reachable TSM;
- checking row counts after large data merges;
- checking spatial indexes and query performance.

These checks were used to identify and resolve processing problems before the derived datasets were used in the final model.

---

## Overall Technical Architecture

The overall technical workflow can be summarised as:

Source cadastral data
│
├── SG / SR text data
│   └── AWK + Python
│
└── Spatial data
    └── PostgreSQL/PostGIS
            │
            ├── Geometry processing
            ├── Terrain / vegetation
            └── TSM / network analysis
            │
            ↓
       Parcel cost model
            │
            ├── Spatial aggregation
            │   └── Parcel / block / allotment
            │
            └── Graph representation
                └── Neo4j
            │
            ↓
       Analysis and mapping

The repository provides selected code examples from these workflows rather than a complete copy of the original datasets or database environment.
