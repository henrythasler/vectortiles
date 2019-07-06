provider "aws" {
  version = "~> 2.16"
  profile = "default"
  region  = var.region
}

resource "aws_db_instance" "osmdata" {
  engine              = "postgres"
  engine_version      = "11.2"
  instance_class      = var.postgres_instance_class
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = var.postgres_user
  password            = var.postgres_password
  name                = "world"
  skip_final_snapshot = true
}

resource "aws_s3_bucket" "gis_data_0000" {
  bucket = "gis-data-0000"
  acl = "private"
  force_destroy = true
}

resource "aws_s3_bucket_object" "preprocessing" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/preprocessing.sh"
  source = "./scripts/preprocessing.sh"
  etag   = "${filemd5("./scripts/preprocessing.sh")}"
}

resource "aws_s3_bucket_object" "import" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/import.sh"
  source = "./scripts/import.sh"
  etag   = "${filemd5("./scripts/import.sh")}"
}

resource "aws_s3_bucket_object" "download" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/download.sh"
  source = "./scripts/download.sh"
  etag   = "${filemd5("./scripts/download.sh")}"
}

resource "aws_s3_bucket_object" "mapping" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "imposm/mapping.yaml"
  source = "./../../import/mapping.yaml"
  etag   = "${filemd5("./../../import/mapping.yaml")}"
}

resource "aws_batch_job_definition" "name" {
  name = "import_into_database"
  type = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["import.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 2048,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.import.bucket}/${aws_s3_bucket_object.import.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${aws_db_instance.osmdata.address}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"},
        {"name": "IMPORT_FILE", "value": "oberfranken-latest.osm.pbf"}
    ],
    "mountPoints": [],
    "ulimits": []
}
CONTAINER_PROPERTIES  
}
