import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue import DynamicFrame


def sparkSqlQuery(glueContext, query, mapping, transformation_ctx) -> DynamicFrame:
    for alias, frame in mapping.items():
        frame.toDF().createOrReplaceTempView(alias)
    result = spark.sql(query)
    return DynamicFrame.fromDF(result, glueContext, transformation_ctx)


args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node order_items
order_items_node1700413845988 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="order_items",
    transformation_ctx="order_items_node1700413845988",
)

# Script generated for node orders
orders_node1700413845821 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="orders",
    transformation_ctx="orders_node1700413845821",
)

# Script generated for node events
events_node1700413847821 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="events",
    transformation_ctx="events_node1700413847821",
)

# Script generated for node products
products_node1700413845620 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="products",
    transformation_ctx="products_node1700413845620",
)

# Script generated for node distribution_center
distribution_center_node1700413848221 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="distribution_centers",
    transformation_ctx="distribution_center_node1700413848221",
)

# Script generated for node users
users_node1700413845001 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="users",
    transformation_ctx="users_node1700413845001",
)

# Script generated for node inventory_items
inventory_items_node1700413847240 = glueContext.create_dynamic_frame.from_catalog(
    database="shopping_db",
    table_name="inventory_items",
    transformation_ctx="inventory_items_node1700413847240",
)

# Script generated for node profit_level
SqlQuery3 = """
SELECT
		user_id AS user_id,
		CASE
			WHEN total_purchase <= 50 THEN 1
			WHEN total_purchase > 50
			AND total_purchase < 150 THEN 2
			ELSE 3
		END AS profit_level
	FROM
		(
			SELECT
				oi.user_id,
				SUM(sale_price) AS total_purchase
			FROM
				order_items AS oi
			WHERE
				EXTRACT(
					YEAR
					FROM
						TO_TIMESTAMP(oi.created_at)
				) = 2022
				AND oi.status = 'Complete'
			GROUP BY
				oi.user_id
		) AS purchase_summary
"""
profit_level_node1700419876001 = sparkSqlQuery(
    glueContext,
    query=SqlQuery3,
    mapping={"order_items": order_items_node1700413845988},
    transformation_ctx="profit_level_node1700419876001",
)

# Script generated for node returned_order_count
SqlQuery5 = """
SELECT
		u.id AS user_id,
		COUNT(*) AS returned_count
	FROM
		orders o
		JOIN users u ON o.user_id = u.id
	WHERE
		o.status = 'Returned'
		AND EXTRACT(
			YEAR
			FROM
				TO_TIMESTAMP(o.returned_at)
		) = 2022
	GROUP BY
		u.id
"""
returned_order_count_node1700419037392 = sparkSqlQuery(
    glueContext,
    query=SqlQuery5,
    mapping={"users": users_node1700413845001, "orders": orders_node1700413845821},
    transformation_ctx="returned_order_count_node1700419037392",
)

# Script generated for node user_traffic_source
SqlQuery0 = """
SELECT
		user_id,
		traffic_source AS most_traffic_source
	FROM
		(
			SELECT
				e.user_id,
				e.traffic_source,
				ROW_NUMBER() OVER(
					PARTITION BY user_id
					ORDER BY
						COUNT(*) DESC
				) AS source_rank
			FROM
				events e
			GROUP BY
				user_id,
				traffic_source
		) AS source_ranking
	WHERE
		source_rank = 1;
"""
user_traffic_source_node1700420243821 = sparkSqlQuery(
    glueContext,
    query=SqlQuery0,
    mapping={"events": events_node1700413847821},
    transformation_ctx="user_traffic_source_node1700420243821",
)

# Script generated for node distribution_centre_distance
SqlQuery4 = """
SELECT
				u.id as user_id,
				u.age,
				u.state,
				u.country,
				dc.id as dc_id,
				dc.name as nearest_distribution_center,
				u.latitude as user_lat,
				u.longitude as user_lon,
				dc.latitude as dc_lat,
				dc.longitude as dc_lon,
				ROUND(
					6371 * 2 * ASIN(
						SQRT(
							POWER(SIN(RADIANS(dc.latitude - u.latitude) / 2), 2) + COS(RADIANS(u.latitude)) * COS(RADIANS(dc.latitude)) * POWER(SIN(RADIANS(dc.longitude - u.longitude) / 2), 2)
						)
					),
					2
				) AS distance_in_km
			FROM
				users as u
				CROSS JOIN distribution_center as dc
			ORDER BY
				user_id, distance_in_km;
"""
distribution_centre_distance_node1700416300832 = sparkSqlQuery(
    glueContext,
    query=SqlQuery4,
    mapping={
        "users": users_node1700413845001,
        "distribution_center": distribution_center_node1700413848221,
    },
    transformation_ctx="distribution_centre_distance_node1700416300832",
)

# Script generated for node nearest_distribution_center
SqlQuery1 = """
SELECT user_id,
		age,
		state,
		country,
		dc_id,
		nearest_distribution_center,
		distance_in_km
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY distance_in_km) AS rn
    FROM distribution_centre_distance
) AS ranked
WHERE rn = 1
ORDER BY user_id;
"""
nearest_distribution_center_node1700418916665 = sparkSqlQuery(
    glueContext,
    query=SqlQuery1,
    mapping={
        "distribution_centre_distance": distribution_centre_distance_node1700416300832
    },
    transformation_ctx="nearest_distribution_center_node1700418916665",
)

# Script generated for node analysis_data
SqlQuery2 = """
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
FROM
	NearestDistribution nd
	LEFT JOIN ReturnedOrdersCount roc ON nd.user_id = roc.user_id
	LEFT JOIN ProfitLevel pl ON nd.user_id = pl.user_id
	LEFT JOIN UserTrafficSource uts ON nd.user_id = uts.user_id
ORDER BY
	nd.user_id;
"""
analysis_data_node1700420369197 = sparkSqlQuery(
    glueContext,
    query=SqlQuery2,
    mapping={
        "UserTrafficSource": user_traffic_source_node1700420243821,
        "ProfitLevel": profit_level_node1700419876001,
        "ReturnedOrdersCount": returned_order_count_node1700419037392,
        "NearestDistribution": nearest_distribution_center_node1700418916665,
    },
    transformation_ctx="analysis_data_node1700420369197",
)

# Script generated for node Amazon Redshift
AmazonRedshift_node1700427925040 = glueContext.write_dynamic_frame.from_options(
    frame=analysis_data_node1700420369197,
    connection_type="redshift",
    connection_options={
        "redshiftTmpDir": "s3://aws-glue-assets-522556021711-eu-central-1/temporary/",
        "useConnectionProperties": "true",
        "dbtable": "public.analysis_data",
        "connectionName": "Jdbc connection",
        "preactions": "CREATE TABLE IF NOT EXISTS public.analysis_data (user_id VARCHAR, age VARCHAR, state VARCHAR, country VARCHAR, dc_id VARCHAR, nearest_distribution_center VARCHAR, distance_in_km DOUBLE PRECISION, returned_count VARCHAR, profit_level INTEGER, most_traffic_source VARCHAR); TRUNCATE TABLE public.analysis_data;",
    },
    transformation_ctx="AmazonRedshift_node1700427925040",
)

job.commit()
