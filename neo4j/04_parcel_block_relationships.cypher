CALL () {
  LOAD CSV WITH HEADERS FROM 'file:///beacon_parcel_block_link.csv' AS row
  WITH row
  WHERE row.parcel_id IS NOT NULL AND trim(row.parcel_id) <> ''
    AND row.block_id_v2_1 IS NOT NULL AND trim(row.block_id_v2_1) <> ''

  WITH DISTINCT
    trim(row.parcel_id)          AS pid_s,         // string
    toInteger(row.block_id_v2_1) AS bid_i          // integer

  MATCH (p:Parcel {parcel_id: pid_s})
  MATCH (b:Block  {block_id_v2_1: bid_i})
  MERGE (p)-[:IN_BLOCK]->(b)
} IN TRANSACTIONS OF 5000 ROWS;
