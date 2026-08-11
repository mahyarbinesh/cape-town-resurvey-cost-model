-- 1. Dump all vertices per parcel
DROP TABLE IF EXISTS parcel_vertices;
CREATE TABLE parcel_vertices AS
SELECT 
    parcel_uid,
    (dp).geom AS vertex_geom
FROM (
    SELECT parcel_uid, ST_DumpPoints(geom) AS dp
    FROM parcels_clean_utm_tol005
) AS dump;

-- Optional: Add spatial index for faster clustering
CREATE INDEX idx_parcel_vertices_geom 
ON parcel_vertices USING GIST(vertex_geom);

-- 2. Cluster vertices into global beacons (tolerance = 0.05 m)
DROP TABLE IF EXISTS global_beacons;
CREATE TABLE global_beacons AS
SELECT 
    row_number() OVER () AS beacon_id,
    ST_Centroid(ST_Collect(cluster)) AS beacon_geom
FROM (
    SELECT unnest(ST_ClusterWithin(vertex_geom, 0.05)) AS cluster
    FROM parcel_vertices
) AS clusters
GROUP BY cluster;

-- Add spatial index on beacons
CREATE INDEX idx_global_beacons_geom 
ON global_beacons USING GIST(beacon_geom);

-- 3. Create Parcel–Beacon link table (many-to-many)
DROP TABLE IF EXISTS parcel_beacon_link;
CREATE TABLE parcel_beacon_link AS
SELECT DISTINCT
    v.parcel_uid,
    b.beacon_id
FROM parcel_vertices v
JOIN global_beacons b
  ON ST_DWithin(v.vertex_geom, b.beacon_geom, 0.05);

-- Optional: Indexes for efficient joins/queries
CREATE INDEX idx_parcel_beacon_link_parcel 
ON parcel_beacon_link(parcel_uid);

CREATE INDEX idx_parcel_beacon_link_beacon 
ON parcel_beacon_link(beacon_id);
