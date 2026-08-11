-- Drop the table if it already exists
DROP TABLE IF EXISTS parcels_clean_utm_tol005;

-- Create a new table with 5 cm simplified geometry
CREATE TABLE parcels_clean_utm_tol005 AS
SELECT 
    parcel_uid,
    gid,
    gid_orig,
    prcl_key,
    prcl_type,
    lstatus,
    wstatus,
    geom_area,
    comments,
    tag_x,
    tag_y,
    tag_value,
    tag_size,
    tag_angle,
    tag_just,
    id AS sg_id,
    date_stamp,
    area_m2,
    perimeter_m,
    ST_SimplifyPreserveTopology(geom_clean, 0.05) AS geom
FROM parcels_clean_utm;

-- Add vertex count columns and tolerance metadata
ALTER TABLE parcels_clean_utm_tol005
ADD COLUMN vertex_count_raw integer,
ADD COLUMN vertex_count_clean integer,
ADD COLUMN simplification_tolerance_m double precision;

-- Populate vertex counts and tolerance
UPDATE parcels_clean_utm_tol005
SET vertex_count_raw = ST_NPoints(geom),
    vertex_count_clean = ST_NPoints(geom) - 1,
    simplification_tolerance_m = 0.05;

-- Make parcel_uid the primary key
ALTER TABLE parcels_clean_utm_tol005
ADD PRIMARY KEY (parcel_uid);

-- Create spatial index for performance
CREATE INDEX parcels_clean_utm_tol005_geom_idx
ON parcels_clean_utm_tol005
USING GIST (geom);
