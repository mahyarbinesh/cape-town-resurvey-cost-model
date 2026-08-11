// Create constraints for fast Parcel and Beacon matching
CREATE CONSTRAINT parcel_id_unique IF NOT EXISTS
FOR (p:Parcel) REQUIRE p.parcel_id IS UNIQUE;

CREATE CONSTRAINT beacon_id_unique IF NOT EXISTS
FOR (b:Beacon) REQUIRE b.beacon_id IS UNIQUE;


// Import parcel–beacon relationships in small transactions
CALL () {
  LOAD CSV WITH HEADERS
  FROM 'file:///beacon_parcel_block_link.csv' AS row

  WITH row
  WHERE row.parcel_id IS NOT NULL
    AND trim(row.parcel_id) <> ''
    AND row.beacon_id IS NOT NULL
    AND trim(row.beacon_id) <> ''

  // IDs are strings in the CSV and in the Neo4j nodes.
  MATCH (p:Parcel {parcel_id: trim(row.parcel_id)})
  MATCH (bn:Beacon {beacon_id: trim(row.beacon_id)})

  MERGE (p)-[:HAS_BEACON]->(bn)

} IN TRANSACTIONS OF 5000 ROWS;
