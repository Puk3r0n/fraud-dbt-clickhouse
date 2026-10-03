SELECT
    us_state,
    argMax(cat_id, (amount, transaction_time)) AS top_category,
    max(amount)                                AS max_amount
FROM hw2.transactions
GROUP BY us_state
ORDER BY us_state
