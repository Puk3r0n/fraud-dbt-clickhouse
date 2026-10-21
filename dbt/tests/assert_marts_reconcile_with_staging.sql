with staging as (
    select
        count() as tx_count,
        countIf(is_fraud = 1) as fraud_count
    from {{ ref('stg_transactions') }}
),

marts as (
    select
        'mart_daily_state_metrics' as mart,
        sum(tx_count) as tx_count,
        sum(fraud_count) as fraud_count
    from {{ ref('mart_daily_state_metrics') }}

    union all

    select
        'mart_fraud_by_category' as mart,
        sum(tx_count) as tx_count,
        sum(fraud_count) as fraud_count
    from {{ ref('mart_fraud_by_category') }}

    union all

    select
        'mart_fraud_by_state' as mart,
        sum(tx_count) as tx_count,
        sum(fraud_count) as fraud_count
    from {{ ref('mart_fraud_by_state') }}

    union all

    select
        'mart_customer_risk_profile' as mart,
        sum(tx_count) as tx_count,
        sum(fraud_count) as fraud_count
    from {{ ref('mart_customer_risk_profile') }}

    union all

    select
        'mart_hourly_fraud_pattern' as mart,
        sum(tx_count) as tx_count,
        sum(fraud_count) as fraud_count
    from {{ ref('mart_hourly_fraud_pattern') }}

    union all

    select
        'mart_merchant_analytics' as mart,
        sum(tx_count) as tx_count,
        sum(fraud_count) as fraud_count
    from {{ ref('mart_merchant_analytics') }}
)

select marts.*
from marts
cross join staging
where marts.tx_count != staging.tx_count or marts.fraud_count != staging.fraud_count
