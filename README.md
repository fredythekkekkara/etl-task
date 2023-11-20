# ETL Task using AWS

An automated Extract, Transform, Load (ETL) pipeline, empowered by cloud technology, designed to streamline data processing and enable efficient insights generation.

## Description

The ETL Task using AWS project automates the process of extracting data from various sources, transforming it, and loading it into a Redshift cluster. Leveraging AWS services such as Glue, Lambda, and CloudWatch, this pipeline offers a comprehensive solution for efficient data processing.

![Cloud Infrastructure](https://github.com/fredythekkekkara/etl-task/blob/master/data_engineering_task.001.jpeg))

## Files

### 1. `backend.tf`
   - Terraform backend code to store the state file in an S3 bucket.
   - Explanation: Keeping the state file external in an S3 bucket ensures better collaboration among team members and enables state locking, preventing conflicts during simultaneous executions.

### 2. `etl_job_script.py`
   - Contains data transformation logic fetching data from the S3 Glue catalog.
   - Executes SQL queries for data transformation and stores the final dataset into the Redshift cluster.
   - Note: This script is stored in an S3 bucket and referenced in `main.tf` when creating the Glue job.

### 3. `etl_job_trigger.py`
   - Python script to trigger Glue jobs programmatically using a Lambda function.
   - Triggers the script upon successful completion of crawling jobs specified in `main.tf`, executed weekly on Monday at 10 AM, writing data into the Glue catalog database tables.
   - AWS CloudWatch listens for the success of crawling jobs to trigger this Lambda function.

### 4. `local.tf`
   - Contains local configurations for the infrastructure.

### 5. `main.tf`
   - Infrastructure-as-Code (IaC) using Terraform to generate infrastructure components like S3 buckets, Glue catalog database, Glue crawlers, and a Redshift data lake.
   - Advantage of using Terraform: Facilitates reproducibility, scalability, and consistency by defining infrastructure in code.

### 6. `result_query.sql`
   - SQL statement implementing business logic for a data mart.
   - Provides customer-centric features such as age, country, state, nearest distribution center, product return rate, and customer profit levels.
   - Introduces customer profit level categorization (Level 1, 2, 3) based on purchase amounts.
   - Feature enhancement: Most Traffic Source metric incorporation for improved marketing campaigns.

### 7. `variables.tf`
   - Terraform variables file enabling configurations for the infrastructure.
   - Modification of configurations can be done within this file as needed.

