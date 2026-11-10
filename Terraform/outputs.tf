output "database_address" {
  description = "The public endpoint address of the RDS database."
  value       = module.database_module.database_address
}

output "database_port" {
  description = "The port of the RDS database."
  value       = module.database_module.database_port
}

output "database_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing database master credentials."
  value       = module.database_module.database_secret_arn
}
