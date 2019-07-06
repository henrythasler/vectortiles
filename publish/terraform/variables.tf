variable "region" {
  default = "eu-central-1"
}

variable "postgres_instance_class" {
  default = "db.t2.micro"
}

variable "postgres_password" {}
variable "postgres_user" {
  default = "postgres"
}
variable "database_local" {
  default = "local"
}
