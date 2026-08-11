LOAD CSV WITH HEADERS FROM 'file:///tsm_nodes.csv' AS row
CREATE (:TSM {

  tsm_id: row.tsm_id,
  tsm_code: row.tsm_code,
  x_raw: toFloat(row.x_raw),
  y_raw: toFloat(row.y_raw),
  hght: toFloat(row.hght)

});
