with transactions as (
    select * from {{ ref('stg_transactions') }}
),

customers as (
    select
        customer_id,
        any(first_name) as first_name,
        any(last_name) as last_name,
        any(gender) as gender,
        any(state_code) as state_code,
        any(city) as city,
        count() as tx_count,
        round(sum(amount), 2) as total_amount,
        round(avg(amount), 2) as avg_amount,
        max(amount) as max_amount,
        countIf(is_fraud = 1) as fraud_count,
        {{ rate_pct('countIf(is_fraud = 1)', 'count()') }} as fraud_rate_pct,
        {{ rate_pct('countIf(is_large = 1)', 'count()') }} as large_tx_share_pct,
        uniqExact(merchant) as unique_merchants,
        min(transaction_at) as first_transaction_at,
        max(transaction_at) as last_transaction_at,
        uniqExact(transaction_date) as active_days
    from transactions
    group by customer_id
)

select
    *,
    multiIf(
        fraud_rate_pct >= 5, 'HIGH',
        fraud_count > 0 or large_tx_share_pct >= 10, 'MEDIUM',
        'LOW'
    ) as risk_level
from customers
