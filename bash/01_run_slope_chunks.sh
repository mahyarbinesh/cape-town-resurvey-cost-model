#!/usr/bin/env bash
set -euo pipefail

# ---------- Config (override via environment variables if needed) ----------
DB_NAME="${DB_NAME:-cape_town_cadastre_v2}"
PGUSER="${PGUSER:-postgres}"
PGPASSFILE="${PGPASSFILE:-$HOME/.pgpass}"
CHUNK_SIZE="${CHUNK_SIZE:-10000}"

# Non-overlapping range for this worker
RANGE_START="${RANGE_START:-199999}"
RANGE_END="${RANGE_END:-830000}"

# Per-worker log file
WORKER_TAG="${WORKER_TAG:-A}"
LOG_FILE="${LOG_FILE:-slope_${WORKER_TAG}.log}"

export PGPASSFILE

# ---------- Graceful stop on Ctrl-C ----------
stop_requested=0
trap 'stop_requested=1' INT

# ---------- Ensure results table exists ----------
psql -X -v ON_ERROR_STOP=1 -U "$PGUSER" -d "$DB_NAME" -c "
CREATE TABLE IF NOT EXISTS parcel_slope_metrics_all (
  parcel_uid BIGINT PRIMARY KEY,
  slope_min DOUBLE PRECISION,
  slope_max DOUBLE PRECISION,
  slope_mean DOUBLE PRECISION,
  slope_stddev DOUBLE PRECISION
);"

# ---------- Auto-resume start within this worker's range ----------
start=$(
  psql -X -t -A -U "$PGUSER" -d "$DB_NAME" -c "
    WITH last AS (
      SELECT COALESCE(MAX(parcel_uid), $((RANGE_START-1))) AS m
      FROM parcel_slope_metrics_all
      WHERE parcel_uid BETWEEN ${RANGE_START} AND ${RANGE_END}
    )
    SELECT GREATEST((SELECT m FROM last) + 1, ${RANGE_START});
  "
)

if [[ -z "$start" ]]; then
    start="$RANGE_START"
fi

echo "[$(date)] Worker ${WORKER_TAG} starting. Range=${RANGE_START}-${RANGE_END}, CHUNK_SIZE=${CHUNK_SIZE}, resume_from=${start}" | tee -a "$LOG_FILE"

# ---------- Chunk loop ----------
while (( start <= RANGE_END )); do

  end=$(( start + CHUNK_SIZE - 1 ))

  if (( end > RANGE_END )); then
      end="$RANGE_END"
  fi

  echo "[$(date)] Processing ${start}-${end}" | tee -a "$LOG_FILE"

  t0=$(date +%s)

  # ---------- Clip raster tiles to parcels and calculate slope statistics ----------
  psql -X -v ON_ERROR_STOP=1 -U "$PGUSER" -d "$DB_NAME" >>"$LOG_FILE" 2>&1 <<SQL

SET LOCAL work_mem = '256MB';
SET LOCAL maintenance_work_mem = '1GB';
SET LOCAL synchronous_commit = OFF;

WITH parcels AS (
  SELECT z.parcel_uid, z.geom
  FROM z_archive_parcels_clean_utm_tol005 z
  WHERE z.parcel_uid BETWEEN ${start} AND ${end}
    AND NOT EXISTS (
      SELECT 1
      FROM parcel_slope_metrics_all m
      WHERE m.parcel_uid = z.parcel_uid
    )
),
clipped AS (
  SELECT
      p.parcel_uid,
      ST_Clip(s.rast, p.geom, TRUE) AS r
  FROM parcels p
  JOIN slope_cct_gl1_utm34s s
    ON ST_Intersects(p.geom, s.rast)
),
valid AS (
  SELECT parcel_uid, r
  FROM clipped
  WHERE r IS NOT NULL
    AND NOT ST_HasNoBand(r)
    AND (ST_SummaryStats(r, 1, TRUE)).count > 0
)

INSERT INTO parcel_slope_metrics_all (
    parcel_uid,
    slope_min,
    slope_max,
    slope_mean,
    slope_stddev
)
SELECT
    parcel_uid,
    (ST_SummaryStatsAgg(r, 1, TRUE)).min,
    (ST_SummaryStatsAgg(r, 1, TRUE)).max,
    (ST_SummaryStatsAgg(r, 1, TRUE)).mean,
    (ST_SummaryStatsAgg(r, 1, TRUE)).stddev
FROM valid
GROUP BY parcel_uid
ON CONFLICT (parcel_uid) DO NOTHING;

SQL

  # ---------- Post-chunk summary ----------
  after_count=$(
    psql -X -t -A -U "$PGUSER" -d "$DB_NAME" -c "
      SELECT COUNT(*)
      FROM parcel_slope_metrics_all
      WHERE parcel_uid BETWEEN ${start} AND ${end};
    "
  )

  t1=$(date +%s)
  dt=$(( t1 - t0 ))

  echo "[$(date)] Chunk ${start}-${end} done. Inserted_now=${after_count} Duration=${dt}s" | tee -a "$LOG_FILE"

  # ---------- Stop after completing the current chunk ----------
  if (( stop_requested == 1 )); then
      echo "[$(date)] Stop requested. Exiting after chunk ${start}-${end}." | tee -a "$LOG_FILE"
      exit 0
  fi

  start=$(( end + 1 ))

done

echo "[$(date)] Worker ${WORKER_TAG} finished." | tee -a "$LOG_FILE"
