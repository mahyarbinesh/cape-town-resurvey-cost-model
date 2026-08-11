-- Drop old tables if they exist
DROP TABLE IF EXISTS parcels_clean CASCADE;
DROP TABLE IF EXISTS parcels_clean_utm CASCADE;

-- Create the final clean + projected table
CREATE TABLE parcels_clean_utm AS
SELECT
    gid,  -- Replace with unique ID if different

    -- Clean geometry:
    -- Force 2D, make valid, extract polygons,
    -- convert to MultiPolygon, and project to UTM 34S
    ST_Transform(
        ST_Multi(
            ST_CollectionExtract(
                ST_MakeValid(
                    ST_Force2D(geom)
                ),
                3
            )
        ),
        32734
    )::geometry(MultiPolygon, 32734) AS geom,

    -- Compute area in square metres
    ST_Area(
        ST_Transform(
            ST_Multi(
                ST_CollectionExtract(
                    ST_MakeValid(
                        ST_Force2D(geom)
                    ),
                    3
                )
            ),
            32734
        )
    ) AS area_m2,

    -- Compute perimeter in metres
    ST_Perimeter(
        ST_Transform(
            ST_Multi(
                ST_CollectionExtract(
                    ST_MakeValid(
                        ST_Force2D(geom)
                    ),
                    3
                )
            ),
            32734
        )
    ) AS perimeter_m

FROM parcels_raw
WHERE NOT ST_IsEmpty(geom)
  AND ST_Area(geom::geography) > 0;

-- Add a primary key
ALTER TABLE parcels_clean_utm
ADD COLUMN parcel_uid SERIAL PRIMARY KEY;

-- Add a spatial index
CREATE INDEX parcels_clean_utm_geom_idx
ON parcels_clean_utm
USING GIST (geom);
