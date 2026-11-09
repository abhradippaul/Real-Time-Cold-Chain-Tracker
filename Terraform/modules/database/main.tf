resource "aws_db_instance" "this" {
  allocated_storage           = var.allocated_storage
  db_name                     = var.db_name
  engine                      = var.engine
  engine_version              = var.engine_version
  instance_class              = var.instance_class
  manage_master_user_password = true
  skip_final_snapshot         = true
  username                    = var.db_username
  parameter_group_name        = "default.${var.engine}${var.engine_version}"
  tags                        = var.tags
}
