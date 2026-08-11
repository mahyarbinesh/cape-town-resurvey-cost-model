LOAD CSV WITH HEADERS FROM 'file:///parcel_tsm_links.csv' AS row
MATCH (p:Parcel {parcel_uid: row.parcel_uid}),
      (t:TSM {tsm_id: row.tsm_id})
CREATE (p)-[:NEAREST_TSM {
    total_m: toFloat(row.total_m),
    rank: toInteger(row.rank)
}]->(t);
