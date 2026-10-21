with transactions as (
    select * from {{ ref('stg_transactions') }}
),

states as (
    select * from {{ ref('states') }}
),

by_state as (
    select
        state_code,
        count() as tx_count,
        countIf(is_fraud = 1) as fraud_count,
        {{ rate_pct('countIf(is_fraud = 1)', 'count()') }} as fraud_rate_pct,
        uniqExact(customer_id) as unique_customers,
        uniqExactIf(customer_id, is_fraud = 1) as fraud_customers,
        uniqExact(merchant) as unique_merchants,
        round(sum(amount), 2) as total_amount,
        round(sumIf(amount, is_fraud = 1), 2) as fraud_amount
    from transactions
    group by state_code
)

select
    by_state.state_code,
    states.state_name,
    states.region,
    by_state.tx_count,
    by_state.fraud_count,
    by_state.fraud_rate_pct,
    by_state.unique_customers,
    by_state.fraud_customers,
    by_state.unique_merchants,
    by_state.total_amount,
    by_state.fraud_amount
from by_state
left join states on by_state.state_code = states.state_code
