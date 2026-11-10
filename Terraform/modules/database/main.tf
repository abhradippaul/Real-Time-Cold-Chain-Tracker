data "aws_vpc" "default" {
  default = true
}

locals {
  db_port = var.engine == "postgres" ? 5432 : 3306
}

resource "aws_security_group" "database" {
  name_prefix = "${var.db_name}-rds-sg-"
  description = "Security group for RDS instance allowing local/client access"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "Database client access"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.db_name}-rds-sg"
  })
}

resource "aws_db_instance" "this" {
  allocated_storage           = var.allocated_storage
  db_name                     = var.db_name
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  identifier                  = var.database_identifier
  manage_master_user_password = true
  skip_final_snapshot         = true
  publicly_accessible         = true
  vpc_security_group_ids      = [aws_security_group.database.id]
  username                    = var.db_username
  tags                        = var.tags
}
