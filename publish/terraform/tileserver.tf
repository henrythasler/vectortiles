provider "aws" {
  version = "~> 2.16"
  profile = "default"
  region  = var.region
}

resource "aws_db_instance" "osmdata" {
  engine              = "postgres"
  engine_version      = "11.2"
  instance_class      = "db.t2.micro"
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = "postgres"
  password            = var.postgres_password
  name                = "world"
  skip_final_snapshot = true
}
