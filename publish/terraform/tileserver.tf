provider "aws" {
  version = "~> 2.16"
  profile = "default"
  region  = var.region
}

resource "aws_db_instance" "osmdata" {
  engine              = "postgres"
  engine_version      = "11.2"
  identifier          = "osmdata"
  instance_class      = var.postgres_instance_class
  allocated_storage   = 20
  storage_type        = "gp2"
  username            = var.postgres_user
  password            = var.postgres_password
  name                = "world"
  skip_final_snapshot = true
}

resource "aws_s3_bucket" "gis_data_0000" {
  bucket        = "gis-data-0000"
  acl           = "private"
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

resource "aws_s3_bucket_object" "postprocessing" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/postprocessing.sh"
  source = "../../import/postprocessing.sh"
  etag   = "${filemd5("../../import/postprocessing.sh")}"
}

resource "aws_s3_bucket_object" "shp_download" {
  bucket = "${aws_s3_bucket.gis_data_0000.id}"
  key    = "scripts/shp_download.sh"
  source = "./scripts/shp_download.sh"
  etag   = "${filemd5("./scripts/shp_download.sh")}"
}

resource "aws_batch_job_definition" "prepare_local_database" {
  name                 = "prepare_local_database"
  type                 = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["preprocessing.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.preprocessing.bucket}/${aws_s3_bucket_object.preprocessing.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${aws_db_instance.osmdata.address}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
CONTAINER_PROPERTIES  
}

resource "aws_batch_job_definition" "download_pbf" {
  name                 = "download_pbf"
  type                 = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["download.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.download.bucket}/${aws_s3_bucket_object.download.id}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"},
        {"name": "DOWNLOAD_URL", "value": "http://download.geofabrik.de/europe/germany/bayern/oberfranken-latest.osm.pbf"},
        {"name": "OBJECT_NAME", "value": "oberfranken-latest.osm.pbf"}
    ],
    "mountPoints": [],
    "ulimits": []
}
CONTAINER_PROPERTIES  
}

resource "aws_batch_job_definition" "import_into_database" {
  name                 = "import_into_database"
  type                 = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["import.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 2048,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "IMPORT_FILE", "value": "oberfranken-latest.osm.pbf"},
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.import.bucket}/${aws_s3_bucket_object.import.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${aws_db_instance.osmdata.address}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"},
        {"name": "GIS_DATA_BUCKET", "value": "${aws_s3_bucket.gis_data_0000.id}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
CONTAINER_PROPERTIES  
}


resource "aws_batch_job_definition" "postprocessing" {
  name                 = "postprocessing"
  type                 = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["postprocessing.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 2048,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.postprocessing.bucket}/${aws_s3_bucket_object.postprocessing.id}"},
        {"name": "POSTGIS_HOSTNAME", "value": "${aws_db_instance.osmdata.address}"},
        {"name": "POSTGIS_USER", "value": "${var.postgres_user}"},
        {"name": "DATABASE_NAME", "value": "${var.database_local}"},
        {"name": "PGPASSWORD", "value": "${var.postgres_password}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
CONTAINER_PROPERTIES  
}

resource "aws_batch_job_definition" "shp_download" {
  name                 = "shp_download"
  type                 = "container"
  container_properties = <<CONTAINER_PROPERTIES
{
    "command": ["shp_download.sh"],
    "image": "324094553422.dkr.ecr.eu-central-1.amazonaws.com/postgis-client:latest",
    "memory": 512,
    "vcpus": 1,
    "jobRoleArn": "arn:aws:iam::324094553422:role/ecsTaskExecutionRole",
    "volumes": [],
    "environment": [
        {"name": "BATCH_FILE_TYPE", "value": "script"},
        {"name": "BATCH_FILE_S3_URL", "value": "s3://${aws_s3_bucket_object.shp_download.bucket}/${aws_s3_bucket_object.shp_download.id}"}
    ],
    "mountPoints": [],
    "ulimits": []
}
CONTAINER_PROPERTIES  
}