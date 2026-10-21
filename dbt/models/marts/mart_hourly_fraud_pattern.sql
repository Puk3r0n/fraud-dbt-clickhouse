with transactions as (
    select * from {{ ref('stg_transactions') }}
),

overall as (
    select countIf(is_fraud = 1) / count() as overall_fraud_rate
    from transactions
),

by_window as (
    select
        day_of_week,
        transaction_hour,
        count() as tx_count,
        countIf(is_fraud = 1) as fraud_count,
        {{ rate_pct('countIf(is_fraud = 1)', 'count()') }} as fraud_rate_pct,
        round(avg(amount), 2) as avg_amount,
        round(avgIf(amount, is_fraud = 1), 2) as avg_fraud_amount
    from transactions
    group by day_of_week, transaction_hour
)

select
    by_window.day_of_week,
    {{ dbt_date.day_name('toDate(\'2024-01-07\') + by_window.day_of_week', short=false) }} as day_name,
    by_window.transaction_hour,
    by_window.tx_count,
    by_window.fraud_count,
    by_window.fraud_rate_pct,
    by_window.avg_amount,
    by_window.avg_fraud_amount,
    round(by_window.fraud_rate_pct / 100 / overall.overall_fraud_rate, 2) as risk_index,
    toUInt8(by_window.fraud_rate_pct / 100 / overall.overall_fraud_rate >= 2) as is_high_risk_window
from by_window
cross join overall
