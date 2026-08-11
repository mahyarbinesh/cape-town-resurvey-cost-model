-- Filter urban parcels (<30,000 m²)
DROP TABLE IF EXISTS blocks_urban_lt30k_clean;

CREATE TABLE blocks_urban_lt30k_clean AS
SELECT *
FROM parcels_active
WHERE ST_Area(geom) < 30000;

CREATE INDEX blocks_urban_lt30k_clean_geom_idx
ON blocks_urban_lt30k_clean USING GIST (geom);


-- Buffer parcels by 0.25 m to close gaps for block formation
DROP TABLE IF EXISTS blocks_buffered_lt30k_clean;

CREATE TABLE blocks_buffered_lt30k_clean AS
SELECT parcel_uid,
       ST_Buffer(geom, 0.25, 'join=mitre') AS buffered_geom
FROM blocks_urban_lt30k_clean;

CREATE INDEX blocks_buffered_lt30k_clean_geom_idx
ON blocks_buffered_lt30k_clean USING GIST (buffered_geom);


-- Union buffered geometries into initial block polygons
DROP TABLE IF EXISTS blocks_union_lt30k_clean;

CREATE TABLE blocks_union_lt30k_clean AS
SELECT (ST_Dump(ST_Union(buffered_geom))).geom AS block_geom
FROM blocks_buffered_lt30k_clean;

CREATE INDEX blocks_union_lt30k_clean_geom_idx
ON blocks_union_lt30k_clean USING GIST (block_geom);


-- Shrink blocks back by 0.25 m to restore parcel boundaries
DROP TABLE IF EXISTS blocks_final_lt30k_clean;

CREATE TABLE blocks_final_lt30k_clean AS
SELECT row_number() OVER () AS block_id,
       ST_Buffer(block_geom, -0.25, 'join=mitre') AS geom
FROM blocks_union_lt30k_clean;

CREATE INDEX blocks_final_lt30k_clean_geom_idx
ON blocks_final_lt30k_clean USING GIST (geom);


-- Remove holes: keep only the exterior ring polygons
DROP TABLE IF EXISTS blocks_noholes_lt30k_clean;

CREATE TABLE blocks_noholes_lt30k_clean AS
SELECT block_id,
       (ST_Dump(
           ST_MakePolygon(
               ST_ExteriorRing((ST_Dump(geom)).geom)
           )
       )).geom AS geom
FROM blocks_final_lt30k_clean;

CREATE INDEX blocks_noholes_lt30k_clean_geom_idx
ON blocks_noholes_lt30k_clean USING GIST (geom);


-- Identify overlapping parent-like blocks
DROP TABLE IF EXISTS urban_overlapping_big;

CREATE TABLE urban_overlapping_big AS
SELECT DISTINCT a.block_id,
       ST_Area(a.geom) AS area_m2
FROM blocks_noholes_lt30k_clean a
JOIN blocks_noholes_lt30k_clean b
  ON a.block_id <> b.block_id
 AND ST_Contains(a.geom, b.geom)
WHERE ST_Area(a.geom) > ST_Area(b.geom)
ORDER BY area_m2 DESC;


-- Create the final clean urban block layer
DROP TABLE IF EXISTS blocks_urban_30k;

CREATE TABLE blocks_urban_30k AS
SELECT *
FROM blocks_noholes_lt30k_clean
WHERE block_id NOT IN (
    SELECT block_id
    FROM urban_overlapping_big
);

CREATE INDEX blocks_urban_30k_geom_idx
ON blocks_urban_30k USING GIST (geom);


-- Verify that final blocks are non-overlapping
SELECT COUNT(*) AS overlaps_remaining
FROM blocks_urban_30k a
JOIN blocks_urban_30k b
  ON a.block_id < b.block_id
 AND ST_Intersects(a.geom, b.geom);


-- Assign each parcel to the block with the largest
-- intersection area
DROP TABLE IF EXISTS parcels_urban_30k_block_final;

CREATE TABLE parcels_urban_30k_block_final AS
WITH parcel_block_areas AS (
    SELECT p.parcel_uid,
           b.block_id,
           ST_Area(ST_Intersection(p.geom, b.geom)) AS intersect_area,
           p.geom
    FROM parcels_active p
    JOIN blocks_urban_30k b
      ON ST_Intersects(p.geom, b.geom)
    WHERE ST_Area(p.geom) < 30000
),
ranked AS (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY parcel_uid
               ORDER BY intersect_area DESC
           ) AS rn
    FROM parcel_block_areas
)
SELECT parcel_uid, block_id, geom
FROM ranked
WHERE rn = 1;


-- Create spatial index
CREATE INDEX parcels_urban_30k_block_final_geom_idx
ON parcels_urban_30k_block_final
USING GIST (geom);


-- Verify unique parcel assignment
SELECT COUNT(*), COUNT(DISTINCT parcel_uid)
FROM parcels_urban_30k_block_final;
