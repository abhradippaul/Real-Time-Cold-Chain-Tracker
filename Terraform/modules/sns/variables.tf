variable "sns_name" {
  type = string
}

variable "tags" {
  type        = map(string)
  description = "A map of tags to assign to the resource."
}
