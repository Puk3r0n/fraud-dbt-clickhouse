with transactions as (
    select * from {{ ref('stg_transactions') }}
),

by_category as (
    select
        category,
        count() as tx_count,
        countIf(is_fraud = 1) as fraud_count,
        {{ rate_pct('countIf(is_fraud = 1)', 'count()') }} as fraud_rate_pct,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        round(avgIf(amount, is_fraud = 1), 2) as avg_fraud_amount,
        round(avgIf(amount, is_fraud = 0), 2) as avg_legit_amount,
        {{ rate_pct('sumIf(amount, is_fraud = 1)', 'sum(amount)') }} as fraud_amount_share_pct
    from transactions
    group by category
)

select
    *,
    row_number() over (order by fraud_rate_pct desc) as fraud_rate_rank
from by_category
