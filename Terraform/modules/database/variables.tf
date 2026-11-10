variable "engine" {
  description = "The name of the database engine to use."
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The version of the database engine to use."
  type        = string
  default     = "16.4"
}

variable "instance_class" {
  description = "The type of database instance to use."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
  default     = "temperature"
}

variable "db_username" {
  description = "The username for the database."
  type        = string
  default     = "admin"
}

variable "allocated_storage" {
  description = "The amount of storage to allocate for the database."
  type        = number
  default     = 20
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the database."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "A map of tags to assign to the database."
  type        = map(string)
}

variable "database_identifier" {
  description = "The identifier of the database."
  type        = string
}
