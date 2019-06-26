provider "aws" {
  version = "~> 2.16"
  profile = "default"
  region  = "eu-central-1"
}

resource "aws_instance" "testing" {
  ami           = "ami-0cd855c8009cb26ef"
  instance_type = "t2.micro"
}
