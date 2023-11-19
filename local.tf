locals {
  jdbc_connection_string = "jdbc:redshift://${aws_redshift_cluster.etl-job-cluster.endpoint}:${aws_redshift_cluster.etl-job-cluster.port}/${var.db_name}?user=${var.username}&password=${var.password}"
}