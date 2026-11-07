SELECT
    genres_0                                        AS genre,
    COUNT(*)                                        AS movies,
    ROUND(AVG(TRY_CAST(rating AS DOUBLE)), 2)       AS avg_rating,
    ROUND(AVG(TRY_CAST(running_time_secs AS INTEGER)) / 60.0, 1) AS avg_runtime_min
FROM "data"
WHERE genres_0 IS NOT NULL AND genres_0 <> ''
GROUP BY genres_0
ORDER BY movies DESC
LIMIT 5;