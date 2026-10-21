select
    customer_id,
    risk_level,
    fraud_count
from {{ ref('mart_customer_risk_profile') }}
where
    (risk_level = 'HIGH' and fraud_count = 0)
    or (risk_level = 'LOW' and fraud_count > 0)
