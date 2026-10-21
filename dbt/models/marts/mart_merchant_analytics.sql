with transactions as (
    select * from {{ ref('stg_transactions') }}
),

merchants as (
    select
        merchant,
        topK(1) (category)[1] as main_category,
        count() as tx_count,
        round(sum(amount), 2) as turnover,
        round(avg(amount), 2) as avg_amount,
        countIf(is_fraud = 1) as fraud_count,
        {{ rate_pct('countIf(is_fraud = 1)', 'count()') }} as fraud_rate_pct,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount,
        uniqExact(customer_id) as unique_customers,
        uniqExact(state_code) as unique_states,
        min(transaction_at) as first_transaction_at,
        max(transaction_at) as last_transaction_at
    from transactions
    group by merchant
)

select
    *,
    toUInt8(
        tx_count >= {{ var('suspicious_merchant_min_tx') }}
        and fraud_rate_pct >= {{ var('suspicious_merchant_fraud_rate') }}
    ) as is_suspicious
from merchants
