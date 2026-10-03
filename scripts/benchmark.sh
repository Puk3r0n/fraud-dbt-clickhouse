#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

ch() { docker compose exec -T clickhouse clickhouse-client "$@"; }
RUN_ID="bench_$(date +%s)"

for q in 03_query_baseline 03_query_top_category_by_state 04_query_from_agg; do
  for _ in 1 2 3 4 5; do
    ch --log_comment="${RUN_ID}:${q}" --format Null < "sql/${q}.sql"
  done
done
ch -q "SYSTEM FLUSH LOGS"

echo "== Запросы (5 запусков каждый)"
ch --format PrettyCompactMonoBlock -q "
SELECT replaceOne(log_comment, '${RUN_ID}:', '') AS query,
       min(query_duration_ms) AS min_ms, median(query_duration_ms) AS median_ms,
       any(read_rows) AS read_rows, formatReadableSize(any(read_bytes)) AS read_bytes
FROM system.query_log
WHERE type = 'QueryFinish' AND log_comment LIKE '${RUN_ID}:%'
GROUP BY query ORDER BY query"

echo "== Хранение"
ch --format PrettyCompactMonoBlock -q "
SELECT table, sum(rows) AS rows, count() AS parts,
       formatReadableSize(sum(data_compressed_bytes)) AS compressed,
       formatReadableSize(sum(data_uncompressed_bytes)) AS uncompressed
FROM system.parts
WHERE database = 'hw2' AND active
GROUP BY table ORDER BY table"
