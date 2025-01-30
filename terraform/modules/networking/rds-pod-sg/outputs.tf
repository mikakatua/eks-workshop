output "catalog_rds_endpoint" {
  description = "The RDS connection endpoint"
  value       = module.catalog_mariadb.db_instance_endpoint
}

output "catalog_sg_id" {
  description = "The SG applied to the catalog pods"
  value       = aws_security_group.catalog_rds_ingress.id
}
