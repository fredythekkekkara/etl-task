variable "s3_paths" {
  description = "List of S3 paths for the crawlers"
  type        = list(string)
  default     = [
    "s3://shopping-data-bucket/data/distribution_centers/", 
    "s3://shopping-data-bucket/data/events/", 
    "s3://shopping-data-bucket/data/order_items/",  
    "s3://shopping-data-bucket/data/orders/",  
    "s3://shopping-data-bucket/data/inventory_items/",  
    "s3://shopping-data-bucket/data/products/",  
    "s3://shopping-data-bucket/data/users/"  
  ]
}



variable "db_name" {
  type = string
  default = "analysis_db"
}

variable "username" {
  type = string
  default = "admin"
}

variable "password" {
  type = string
}