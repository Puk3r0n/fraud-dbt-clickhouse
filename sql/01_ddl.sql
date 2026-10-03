CREATE DATABASE IF NOT EXISTS hw2;

CREATE TABLE IF NOT EXISTS hw2.transactions_kafka
(
    transaction_time String,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        String,
    lat              Float64,
    lon              Float64,
    population_city  Float64,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           Float64
)
ENGINE = Kafka
SETTINGS
    kafka_broker_list = 'kafka:9092',
    kafka_topic_list = 'transactions',
    kafka_group_name = 'clickhouse_raw',
    kafka_format = 'JSONEachRow',
    kafka_num_consumers = 3,
    kafka_skip_broken_messages = 10;

CREATE TABLE IF NOT EXISTS hw2.transactions_raw
(
    transaction_time String,
    merch            String,
    cat_id           String,
    amount           Float64,
    name_1           String,
    name_2           String,
    gender           String,
    street           String,
    one_city         String,
    us_state         String,
    post_code        String,
    lat              Float64,
    lon              Float64,
    population_city  Float64,
    jobs             String,
    merchant_lat     Float64,
    merchant_lon     Float64,
    target           Float64
)
ENGINE = MergeTree
ORDER BY tuple();

CREATE MATERIALIZED VIEW IF NOT EXISTS hw2.transactions_raw_mv
TO hw2.transactions_raw
AS SELECT * FROM hw2.transactions_kafka;
