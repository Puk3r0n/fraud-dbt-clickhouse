with transactions as (
    select * from {{ ref('stg_transactions') }}
),

states as (
    select * from {{ ref('states') }}
),

daily as (
    select
        transaction_date,
        state_code,
        count() as tx_count,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        round(quantileExact(0.95) (amount), 2) as p95_amount,
        countIf(is_large = 1) as large_tx_count,
        {{ rate_pct('countIf(is_large = 1)', 'count()') }} as large_tx_share_pct,
        countIf(is_fraud = 1) as fraud_count,
        {{ rate_pct('countIf(is_fraud = 1)', 'count()') }} as fraud_rate_pct
    from transactions
    group by transaction_date, state_code
)

select
    daily.transaction_date,
    daily.state_code,
    states.state_name,
    states.region,
    daily.tx_count,
    daily.total_amount,
    daily.avg_amount,
    daily.p95_amount,
    daily.large_tx_count,
    daily.large_tx_share_pct,
    daily.fraud_count,
    daily.fraud_rate_pct
from daily
left join states on daily.state_code = states.state_code
