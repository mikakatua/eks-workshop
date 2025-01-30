# Data source to fetch the latest secret version
data "aws_secretsmanager_secret_version" "db_secret" {
  secret_id = var.module_inputs.catalog_db_secret_arn
}

# Extract the secret string and decode the JSON
locals {
  secret_data = jsondecode(data.aws_secretsmanager_secret_version.db_secret.secret_string)
}

module "catalog_mariadb" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "${var.module_inputs.cluster_name}-catalog"

  create_db_option_group    = false
  create_db_parameter_group = false

  engine               = "mariadb"
  engine_version       = "11.4.4"
  instance_class       = "db.t4g.micro"

  # gp2 has a minimum storage size of 20GB for MySQL instances
  allocated_storage = 20

  db_name                     = "catalog"
  username                    = local.secret_data["username"]
  password                    = local.secret_data["password"]
  manage_master_user_password = false
  port                        = 3306

  create_db_subnet_group = true
  db_subnet_group_name   = "${var.module_inputs.cluster_name}-catalog"
  subnet_ids             = var.module_inputs.private_subnets
  vpc_security_group_ids = [module.catalog_rds_ingress.security_group_id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"

  backup_retention_period = 0

  tags = var.module_inputs.tags
}

module "catalog_rds_ingress" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "5.2.0"

  name        = "${var.module_inputs.cluster_name}-catalog-rds"
  description = "Catalog RDS security group"
  vpc_id      = var.module_inputs.vpc_id

  # ingress
  ingress_with_source_security_group_id = [
    {
      from_port                = 3306
      to_port                  = 3306
      protocol                 = "tcp"
      description              = "MySQL access from specific security group"
      source_security_group_id = aws_security_group.catalog_rds_ingress.id
    }
  ]

  tags = var.module_inputs.tags
}

resource "aws_security_group" "catalog_rds_ingress" {
  name        = "${var.module_inputs.cluster_name}-catalog"
  description = "Applied to catalog application pods"
  vpc_id      = var.module_inputs.vpc_id

  ingress {
    description = "Allow inbound HTTP API traffic"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = var.module_inputs.private_subnets_cidr_blocks
  }

  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.module_inputs.tags
}
