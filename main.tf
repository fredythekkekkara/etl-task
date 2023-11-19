provider "aws" {
  region = "eu-central-1"
}


resource "aws_vpc" "etl-job-vpc" {
  cidr_block = "192.168.1.0/24"
}

resource "aws_subnet" "etl-job-subnet-01" {
  cidr_block        = "192.168.1.0/26"
  availability_zone = "eu-central-1a"
  vpc_id            = aws_vpc.etl-job-vpc.id

  tags = {
    Name = "etl-job-subnet-01"
  }
}

resource "aws_subnet" "etl-job-subnet-02" {
  cidr_block        = "192.168.1.64/26"
  availability_zone = "eu-central-1b"
  vpc_id            = aws_vpc.etl-job-vpc.id

  tags = {
    Name = "etl-job-subnet-02"
  }
}

resource "aws_subnet" "etl-job-subnet-03" {
  cidr_block        = "192.168.1.128/25"
  availability_zone = "eu-central-1c"
  vpc_id            = aws_vpc.etl-job-vpc.id

  tags = {
    Name = "etl-job-subnet-03"
  }
}

resource "aws_redshift_subnet_group" "etl-job-redshift-subnet-group" {
  name       = "etl-job-redshift-subnet-group"
  subnet_ids = [aws_subnet.etl-job-subnet-01.id, aws_subnet.etl-job-subnet-02.id, aws_subnet.etl-job-subnet-03.id]

  tags = {
    environment = "Dev"
  }
}

resource "aws_s3_bucket" "shopping-data-bucket" {
  bucket = "shopping-data-bucket"

  tags = {
    Name        = "shopping-data-bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_object" "distribution_centers" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/distribution_centers/distribution_centers.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/distribution_centers.csv"
}
resource "aws_s3_object" "events" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/events/events.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/events.csv"
}
resource "aws_s3_object" "inventory_items" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/inventory_items/inventory_items.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/inventory_items.csv"
}
resource "aws_s3_object" "order_items" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/order_items/order_items.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/order_items.csv"
}
resource "aws_s3_object" "orders" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/orders/orders.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/orders.csv"
}
resource "aws_s3_object" "products" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/products/products.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/products.csv"
}
resource "aws_s3_object" "users" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "data/users/users.csv"
  source = "/Users/fredydavis/Downloads/thelook_ecommerce/users.csv"
}


resource "aws_s3_object" "database" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "database/"
}

resource "aws_s3_object" "temp" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "temp/"
}

resource "aws_s3_object" "script" {
  bucket = aws_s3_bucket.shopping-data-bucket.bucket
  key    = "script/"
  source = "/Users/fredydavis/Downloads/conrad_task/conrad_task_2/etl_job_script.py"
}



resource "aws_iam_role" "glue_role" {
  name = "GlueRoleForS3Access" 
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "glue.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "glue_s3_access_policy" {
  name        = "GlueS3AccessPolicy" # Replace with your desired policy name
  description = "Policy for Glue to access S3 bucket"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ],
        "Resource" : [
          "arn:aws:s3:::shopping-data-bucket", 
          "arn:aws:s3:::shopping-data-bucket/*"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "glue_s3_access_log_policy" {
  name        = "glueS3AccessLogPolicy"
  description = "Policy for Glue to access Cloud watch logs"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "logs:*",
        "Resource" : "*" 
      }
    ]
  })
}


resource "aws_iam_policy" "glue_catalog_access_policy" {
  name        = "glueCatalogAccessPolicy" 
  description = "Policy for Glue to access Cloud watch logs"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "glue:*",
      "Resource": "*"
    }
  ]
}
)
}


resource "aws_iam_policy" "glue_catalog_table_access_policy" {
  name        = "glueCatalogTableAccessPolicy" 
  description = "Policy for Glue to access Cloud watch logs"

  policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "glue:GetTable",
      "Resource": "*"
    }
  ]
}

)
}


resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_access_policy.arn
}

resource "aws_iam_role_policy_attachment" "glue_cloudwatch_logs_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_s3_access_log_policy.arn 
}

resource "aws_iam_role_policy_attachment" "glue_get_database_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_catalog_access_policy.arn 
}

resource "aws_iam_role_policy_attachment" "glue_get_table_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_catalog_table_access_policy.arn 
}


resource "aws_glue_catalog_database" "shopping_db" {
  name = "shopping_db" 
}



resource "aws_glue_crawler" "distribution-centers-crawler" {
  name = "distribution-centers-crawler" 

  database_name = "shopping_db" 

  role = aws_iam_role.glue_role.arn 

  s3_target {
    path = "s3://shopping-data-bucket/data/distribution_centers/" 
  }

  
}


resource "aws_glue_trigger" "start-distribution-centers-trigger" {
  name = "start-distribution-centers-trigger" 
  type = "ON_DEMAND"
  actions {
    crawler_name = aws_glue_crawler.distribution-centers-crawler.name
  }
}






resource "aws_glue_crawler" "s3_crawlers" {
  count = length(var.s3_paths)

  name          = "s3-crawler-${count.index + 1}"
  database_name = aws_glue_catalog_database.shopping_db.name

  role = aws_iam_role.glue_role.arn  

  s3_target {
    path = var.s3_paths[count.index]
  }
  schedule = "cron(0 10 ? * MON *)"
}

resource "aws_redshift_cluster" "etl-job-cluster" {
  cluster_identifier         = "cetl-job-cluster" 
  database_name              = var.db_name       
  master_username            = var.username              
  master_password            = var.password      
  node_type                  = "dc2.large"       
  cluster_type               = "single-node"          
  publicly_accessible        = false  
  cluster_subnet_group_name  = aws_redshift_subnet_group.etl-job-redshift-subnet-group.name
}

/*
output "redshift_jdbc_connection_string" {
  value = "jdbc:redshift://${aws_redshift_cluster.etl-job-cluster.endpoint}:${aws_redshift_cluster.etl-job-cluster.port}/${var.db_name}?user=${var.username}&password=${var.password}"
}
*/
locals {
  jdbc_connection_string = "jdbc:redshift://${aws_redshift_cluster.etl-job-cluster.endpoint}:${aws_redshift_cluster.etl-job-cluster.port}/${var.db_name}?user=${var.username}&password=${var.password}"
}

resource "aws_glue_connection" "redshift_connection" {
  name = "redshift-connection"
  description = "AWS Glue connection to Redshift via JDBC"
  connection_properties = {
    "JDBC_CONNECTION_URL" = local.jdbc_connection_string
    "PASSWORD" = var.username 
    "USERNAME" = var.password
  }
  connection_type = "JDBC"
  physical_connection_requirements {
    availability_zone = "eu-central-1"
    security_group_id_list = ["sg-0359f52b4052cf2aa"]  
    subnet_id = aws_subnet.etl-job-subnet-01.id 
  }
}

resource "aws_glue_job" "etl-data-job" {
  name     = "etl-data-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${aws_s3_bucket.shopping-data-bucket.bucket}/script/etl_job_script.py"
  }
}



