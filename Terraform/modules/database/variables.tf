variable "engine" {
  description = "The name of the database engine to use."
  type        = string
  default     = "postgresql"
}

variable "engine_version" {
  description = "The version of the database engine to use."
  type        = string
  default     = "18.4"
}

variable "instance_class" {
  description = "The type of database instance to use."
  type        = string
  default     = "db.t4g.micro"
}

variable "db_name" {
  description = "The name of the database to create."
  type        = string
}

variable "db_username" {
  description = "The username for the database."
  type        = string
}

variable "allocated_storage" {
  description = "The amount of storage to allocate for the database."
  type        = number
  default     = 10
}

variable "tags" {
  description = "A map of tags to assign to the database."
  type        = map(string)
}
