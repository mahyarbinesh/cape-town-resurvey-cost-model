// Create a uniqueness constraint for Allotment nodes
CREATE CONSTRAINT allotment_code_unique IF NOT EXISTS
FOR (a:Allotment) REQUIRE a.allotment_code IS UNIQUE;


// Create Allotment nodes from distinct parcel values
MATCH (p:Parcel)
WHERE p.allotment_code IS NOT NULL
  AND trim(p.allotment_code) <> ''

WITH DISTINCT
    toUpper(trim(p.allotment_code)) AS code,
    trim(coalesce(p.allotment_name, '')) AS raw_name

WITH
    code,
    CASE
        WHEN raw_name = '' THEN code
        ELSE raw_name
    END AS name

MERGE (a:Allotment {allotment_code: code})
ON CREATE SET a.allotment_name = name;


// Link Parcels to Allotments
MATCH (p:Parcel)
WHERE p.allotment_code IS NOT NULL
  AND trim(p.allotment_code) <> ''

WITH
    p,
    toUpper(trim(p.allotment_code)) AS code

MATCH (a:Allotment {allotment_code: code})

MERGE (p)-[:IN_ALLOTMENT]->(a);


// Quick QA
MATCH (a:Allotment)
RETURN count(a) AS allotments;

MATCH (:Parcel)-[r:IN_ALLOTMENT]->(:Allotment)
RETURN count(r) AS parcel_links;
