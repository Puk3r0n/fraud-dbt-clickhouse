select
    'category' as mart,
    category as entity_key,
    fraud_rate_pct
from {{ ref('mart_fraud_by_category') }}
where fraud_rate_pct < 0 or fraud_rate_pct > 100

union all

select
    'state' as mart,
    state_code as entity_key,
    fraud_rate_pct
from {{ ref('mart_fraud_by_state') }}
where fraud_rate_pct < 0 or fraud_rate_pct > 100

union all

select
    'merchant' as mart,
    merchant as entity_key,
    fraud_rate_pct
from {{ ref('mart_merchant_analytics') }}
where fraud_rate_pct < 0 or fraud_rate_pct > 100
