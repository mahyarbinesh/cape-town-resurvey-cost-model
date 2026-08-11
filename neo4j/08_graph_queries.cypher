// Count beacons associated with each parcel
MATCH (p:Parcel)-[:HAS_BEACON]->(b:Beacon)
RETURN p.parcel_uid, count(b) AS beacon_count
ORDER BY beacon_count DESC
LIMIT 10;


// Count parcels within each block
MATCH (b:Block)<-[:IN_BLOCK]-(p:Parcel)
RETURN b.block_id_v2_1, count(p) AS parcels_per_block
ORDER BY parcels_per_block DESC
LIMIT 10;


// Inspect parcel–TSM relationships
MATCH (p:Parcel)-[:NEAREST_TSM]->(t:TSM)
RETURN p.parcel_uid, t.tsm_code, t.hght
LIMIT 20;


// Count parcels within each allotment
MATCH (a:Allotment)<-[:IN_ALLOTMENT]-(p:Parcel)
RETURN a.allotment_name, count(p) AS total_parcels
ORDER BY total_parcels DESC
LIMIT 10;
