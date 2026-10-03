SELECT
    us_state,
    argMaxMerge(top_category) AS top_category,
    maxMerge(max_amount)      AS max_amount
FROM hw2.top_by_state_agg
GROUP BY us_state
ORDER BY us_state
