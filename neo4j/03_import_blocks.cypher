// Create a uniqueness constraint for Block nodes
CREATE CONSTRAINT block_id_unique IF NOT EXISTS
FOR (b:Block) REQUIRE b.block_id IS UNIQUE;


// Import blocks from CSV in batches
CALL () {
  LOAD CSV WITH HEADERS FROM 'file:///blocks.csv' AS row

  WITH row
  WHERE row.block_id IS NOT NULL
    AND trim(row.block_id) <> ''

  MERGE (b:Block {block_id: toInteger(row.block_id)})

  SET
    b.parcel_count = CASE
      WHEN row.parcel_count = '' THEN NULL
      ELSE toInteger(row.parcel_count)
    END,

    b.block_area_m2 = CASE
      WHEN row.block_area_m2 = '' THEN NULL
      ELSE toFloat(row.block_area_m2)
    END,

    b.total_parcel_area_m2 = CASE
      WHEN row.total_parcel_area_m2 = '' THEN NULL
      ELSE toFloat(row.total_parcel_area_m2)
    END,

    b.fill_ratio = CASE
      WHEN row.fill_ratio = '' THEN NULL
      ELSE toFloat(row.fill_ratio)
    END,

    b.earliest_sg_no = CASE
      WHEN row.earliest_sg_no = '' THEN NULL
      ELSE row.earliest_sg_no
    END,

    b.earliest_sg_year = CASE
      WHEN row.earliest_sg_year = '' THEN NULL
      ELSE toInteger(row.earliest_sg_year)
    END,

    b.latest_sg_no = CASE
      WHEN row.latest_sg_no = '' THEN NULL
      ELSE row.latest_sg_no
    END,

    b.latest_sg_year = CASE
      WHEN row.latest_sg_year = '' THEN NULL
      ELSE toInteger(row.latest_sg_year)
    END,

    b.latest_sr_no = CASE
      WHEN row.latest_sr_no = '' THEN NULL
      ELSE row.latest_sr_no
    END,

    b.latest_sr_year = CASE
      WHEN row.latest_sr_year = '' THEN NULL
      ELSE toInteger(row.latest_sr_year)
    END,

    b.era_earliest = CASE
      WHEN row.era_earliest = '' THEN NULL
      ELSE row.era_earliest
    END,

    b.era_latest = CASE
      WHEN row.era_latest = '' THEN NULL
      ELSE row.era_latest
    END

} IN TRANSACTIONS OF 1000 ROWS;


// Quick validation
MATCH (b:Block)
RETURN count(b);
