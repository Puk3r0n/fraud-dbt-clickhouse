# Kafka в ClickHouse

ДЗ 2 по ML System Design. train.csv загружается в Kafka, ClickHouse читает топик через Kafka engine и materialized view в MergeTree. Есть запрос категории наибольшей транзакции по каждому штату и оптимизированная схема хранения.

## Запуск

Положите train.csv в data/:

    docker compose up -d
    docker compose run --rm producer --file /data/train.csv

## Проверка

    docker compose exec -T clickhouse clickhouse-client --format CSVWithNames \
      < sql/03_query_top_category_by_state.sql > results/top_category_by_state.csv
    ./scripts/benchmark.sh

Результат запроса - results/top_category_by_state.csv, 51 строка.

## Оптимизация

sql/02_ddl_optimized.sql: DateTime и Decimal вместо строк и Float64, LowCardinality, ORDER BY (us_state, cat_id, transaction_time), партиции по месяцу, кодеки Delta и ZSTD, витрина top_by_state_agg на AggregatingMergeTree.

                              сжато      запрос прочитал     время
    базовая таблица          58.6 MiB    47.6 MiB            ~22 мс
    оптимизированная         19.6 MiB    10.5 MiB            ~20 мс
    витрина top_by_state_agg  1.2 KiB    51 строка, 8 KiB    ~1 мс
