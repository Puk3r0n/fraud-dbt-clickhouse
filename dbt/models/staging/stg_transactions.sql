with source as (
    select distinct *
    from {{ source('transactions_db', 'transactions') }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key([
            'transaction_time', 'merch', 'cat_id', 'amount', 'name_1', 'name_2',
            'street', 'post_code', 'lat', 'lon', 'merchant_lat', 'merchant_lon', 'target'
        ]) }} as transaction_id,
        {{ dbt_utils.generate_surrogate_key(['name_1', 'name_2', 'street', 'post_code']) }} as customer_id,
        toDateTime(transaction_time) as transaction_at,
        toDate(transaction_time) as transaction_date,
        toHour(transaction_time) as transaction_hour,
        {{ dbt_date.day_of_week('transaction_time', isoweek=true) }} as day_of_week,
        replaceRegexpOne(trim(merch), '^fraud_', '') as merchant,
        lower(trim(cat_id)) as category,
        round(toFloat64(amount), 2) as amount,
        {{ amount_bucket('amount') }} as amount_bucket,
        toUInt8(amount >= {{ var('large_amount_threshold') }}) as is_large,
        trim(name_1) as first_name,
        trim(name_2) as last_name,
        upper(trim(gender)) as gender,
        trim(one_city) as city,
        upper(trim(us_state)) as state_code,
        trim(post_code) as post_code,
        toUInt32(population_city) as city_population,
        trim(jobs) as job,
        lat as customer_lat,
        lon as customer_lon,
        merchant_lat,
        merchant_lon,
        round(greatCircleDistance(lon, lat, merchant_lon, merchant_lat) / 1000, 2) as distance_km,
        toUInt8(target) as is_fraud
    from source
)

select * from renamed
