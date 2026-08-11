// Create a uniqueness constraint for Parcel nodes
CREATE CONSTRAINT parcel_id_unique IF NOT EXISTS
FOR (p:Parcel) REQUIRE p.parcel_id IS UNIQUE;


// Import one CSV chunk
// Repeat with the corresponding filename for each chunk.

CALL () {
  WITH 'file:///chunks/parcels_part_001.csv' AS url
  LOAD CSV WITH HEADERS FROM url AS row
  WITH row
  WHERE row.`parcel_id:ID(Parcel)` IS NOT NULL

  MERGE (p:Parcel {parcel_id: row.`parcel_id:ID(Parcel)`})

  SET p.wstatus = CASE
        WHEN row.wstatus = '' THEN NULL
        ELSE row.wstatus
      END,

      p.prcl_type = CASE
        WHEN row.prcl_type = '' THEN NULL
        ELSE row.prcl_type
      END,

      p.lstatus = CASE
        WHEN row.lstatus = '' THEN NULL
        ELSE row.lstatus
      END,

      p.prcl_key_lpi = CASE
        WHEN row.prcl_key_lpi = '' THEN NULL
        ELSE row.prcl_key_lpi
      END,

      p.sg_no = CASE
        WHEN row.sg_no = '' THEN NULL
        ELSE row.sg_no
      END,

      p.sg_year = CASE
        WHEN row.sg_year = '' THEN NULL
        ELSE toInteger(row.sg_year)
      END,

      p.sr_no = CASE
        WHEN row.sr_no = '' THEN NULL
        ELSE row.sr_no
      END,

      p.sr_year = CASE
        WHEN row.sr_year = '' THEN NULL
        ELSE toInteger(row.sr_year)
      END,

      p.erf_no = CASE
        WHEN row.erf_no = '' THEN NULL
        ELSE row.erf_no
      END,

      p.allotment_name = CASE
        WHEN row.allotment_name = '' THEN NULL
        ELSE row.allotment_name
      END,

      p.allotment_code = CASE
        WHEN row.allotment_code = '' THEN NULL
        ELSE row.allotment_code
      END,

      p.area_m2 = CASE
        WHEN row.area_m2 = '' THEN NULL
        ELSE toFloat(row.area_m2)
      END,

      p.perimeter_m = CASE
        WHEN row.perimeter_m = '' THEN NULL
        ELSE toFloat(row.perimeter_m)
      END,

      p.vertex_count = CASE
        WHEN row.vertex_count = '' THEN NULL
        ELSE toInteger(row.vertex_count)
      END,

      p.block_id_v2_1 = CASE
        WHEN row.block_id_v2_1 = '' THEN NULL
        ELSE toInteger(row.block_id_v2_1)
      END,

      p.simplification_tolerance_m = CASE
        WHEN row.simplification_tolerance_m = '' THEN NULL
        ELSE toFloat(row.simplification_tolerance_m)
      END,

      p.date_stamp = CASE
        WHEN row.date_stamp = '' THEN NULL
        ELSE row.date_stamp
      END
} IN TRANSACTIONS OF 1000 ROWS;
