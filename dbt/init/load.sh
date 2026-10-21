#!/usr/bin/env bash
set -euo pipefail

ch() { clickhouse-client --host clickhouse "$@"; }

ch --multiquery < /init/01_source.sql

rows=$(ch --query "SELECT count() FROM transactions_db.transactions")
if [ "$rows" -gt 0 ]; then
  echo "transactions_db.transactions уже содержит $rows строк, загрузка пропущена"
  exit 0
fi

ch --date_time_input_format best_effort \
   --query "INSERT INTO transactions_db.transactions FORMAT CSVWithNames" < /data/train.csv
ch --query "SELECT count(), min(transaction_time), max(transaction_time), sum(target) FROM transactions_db.transactions"
