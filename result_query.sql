WITH NearestDistribution AS ( 
    -- Query 1: Find Nearest Distribution Center for Each User 
    SELECT 
        user_id, 
        age, 
        state, 
        country, 
        dc_id, 
        nearest_distribution_center, 
        distance_in_km 
    FROM ( 
        SELECT 
        u.id as user_id, 
        u.age, 
        u.state, 
        u.country, 
        dc.id as dc_id, 
        dc.name as nearest_distribution_center, 
        u.latitude as user_lat, 
        u.longitude as user_lon, 
        dc.latitude as dc_lat, 
        dc.longitude as dc_lon, 
        ROUND( 
            6371 * 2 * ASIN( 
                SQRT( 
                    POWER(SIN(RADIANS(dc.latitude - u.latitude) / 2), 2) + 
                    COS(RADIANS(u.latitude)) * COS(RADIANS(dc.latitude)) * 
                    POWER(SIN(RADIANS(dc.longitude - u.longitude) / 2), 2) 
                ) 
            ), 
            2 
        ) AS distance_in_km, 
        ROW_NUMBER() OVER(PARTITION BY u.id ORDER BY distance_in_km) as rn 
    FROM 
        "awsdatacatalog"."shopping"."users" as u 
    CROSS JOIN 
        "awsdatacatalog"."shopping"."distribution_centers" as dc 
    ORDER BY 
        distance_in_km 
    ) subquery 
    WHERE rn = 1 
), 
ReturnedOrdersCount AS ( 
    -- Query 2: Count of Returned Orders in 2022 by User 
    SELECT u.id AS user_id, COUNT(*) AS returned_count 
    FROM "awsdatacatalog"."shopping"."orders" o 
    JOIN "awsdatacatalog"."shopping"."users" u ON o.user_id = u.id 
    WHERE o.status = 'Returned' 
      AND EXTRACT(YEAR FROM TO_TIMESTAMP(o.returned_at, 'YYYY-MM-DD HH24:MI:SS')) = 2022 
    GROUP BY u.id 
), 
ProfitLevel AS ( 
    -- Query 3: Calculate profit level for each user in 2022 
    SELECT 
        user_id AS user_id, 
        CASE 
            WHEN total_purchase <= 50 THEN 1 
            WHEN total_purchase > 50 AND total_purchase < 150 THEN 2 
            ELSE 3 
        END AS profit_level 
    FROM ( 
        SELECT 
            oi.user_id, 
            SUM(sale_price) AS total_purchase 
        FROM 
            "awsdatacatalog"."shopping"."order_items" AS oi 
        WHERE 
            EXTRACT(YEAR FROM TO_TIMESTAMP(oi.created_at, 'YYYY-MM-DD HH24:MI:SS')) = 2022 -- Filter orders for the year 2022 
            AND oi.status = 'Complete' 
        GROUP BY 
            oi.user_id 
    ) AS purchase_summary 
), 
UserTrafficSource AS ( 
    -- Query 4: Determine most frequent traffic source for each user 
    SELECT 
        user_id, 
        traffic_source AS most_traffic_source 
    FROM ( 
        SELECT 
            e.user_id, 
            e.traffic_source, 
            ROW_NUMBER() OVER(PARTITION BY user_id ORDER BY COUNT(*) DESC) AS source_rank 
        FROM 
            "awsdatacatalog"."shopping"."events" e 
        GROUP BY 
            user_id, traffic_source 
    ) AS source_ranking 
    WHERE source_rank = 1 
) 
-- Joining the results of all queries based on user_id
SELECT 
    nd.user_id, 
    nd.age, 
    nd.state, 
    nd.country, 
    nd.dc_id, 
    nd.nearest_distribution_center, 
    nd.distance_in_km, 
    roc.returned_count, 
    pl.profit_level, 
    uts.most_traffic_source 
FROM NearestDistribution nd 
LEFT JOIN ReturnedOrdersCount roc ON nd.user_id = roc.user_id 
LEFT JOIN ProfitLevel pl ON nd.user_id = pl.user_id 
LEFT JOIN UserTrafficSource uts ON nd.user_id = uts.user_id 
ORDER BY nd.user_id;