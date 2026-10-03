CREATE DATABASE IF NOT EXISTS hw2;

CREATE TABLE IF NOT EXISTS hw2.transactions_kafka_opt
(
    transaction_time String,
    merch            String,
    cat_id           String,
    amount           Decimal(12, 2),
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        UInt32,
    lat              Float64,
    lon              Float64,
    population_city  UInt32,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           UInt8
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse_opt',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 3,
    kafka_skip_broken_messages = 10;

CREATE TABLE IF NOT EXISTS hw2.transactions
(
    transaction_time DateTime                 CODEC(Delta, ZSTD(3)),
    us_state         LowCardinality(String),
    cat_id           LowCardinality(String),
    amount           Decimal(12, 2)           CODEC(ZSTD(3)),
    merch            LowCardinality(String),
    name_1           LowCardinality(String),
    name_2           LowCardinality(String),
    gender           LowCardinality(String),
    street           LowCardinality(String),
    one_city         LowCardinality(String),
    post_code        UInt32                   CODEC(ZSTD(3)),
    lat              Float32                  CODEC(ZSTD(3)),
    lon              Float32                  CODEC(ZSTD(3)),
    population_city  UInt32                   CODEC(ZSTD(3)),
    jobs             LowCardinality(String),
    merchant_lat     Float32                  CODEC(ZSTD(3)),
    merchant_lon     Float32                  CODEC(ZSTD(3)),
    target           UInt8
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(transaction_time)
ORDER BY (us_state, cat_id, transaction_time);

CREATE MATERIALIZED VIEW IF NOT EXISTS hw2.transactions_mv
TO hw2.transactions
AS SELECT
    parseDateTimeBestEffort(transaction_time) AS transaction_time,
    us_state, cat_id,
    amount,
    merch, name_1, name_2, gender, street, one_city, post_code,
    toFloat32(lat)          AS lat,
    toFloat32(lon)          AS lon,
    population_city, jobs,
    toFloat32(merchant_lat) AS merchant_lat,
    toFloat32(merchant_lon) AS merchant_lon,
    target
FROM hw2.transactions_kafka_opt;

CREATE TABLE IF NOT EXISTS hw2.top_by_state_agg
(
    us_state     LowCardinality(String),
    max_amount   AggregateFunction(max, Decimal(12, 2)),
    top_category AggregateFunction(argMax, LowCardinality(String), Tuple(Decimal(12, 2), DateTime))
)
ENGINE = AggregatingMergeTree
ORDER BY us_state;

CREATE MATERIALIZED VIEW IF NOT EXISTS hw2.top_by_state_mv
TO hw2.top_by_state_agg
AS SELECT
    us_state,
    maxState(amount)                                     AS max_amount,
    argMaxState(cat_id, (amount, transaction_time))      AS top_category
FROM hw2.transactions
GROUP BY us_state;
