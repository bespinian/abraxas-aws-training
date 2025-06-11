#  Hands-On: Build Your First Iceberg Table in S3
resource "aws_s3_bucket" "datalake" {
  bucket_prefix = "lakehouse"
  force_destroy = true
}

resource "aws_s3_object" "parquet_upload" {
  bucket = aws_s3_bucket.datalake.bucket
  key    = "data/iceberg-demo/user_events.parquet"
  source = "./lake.parquet"
  etag   = filemd5("./lake.parquet")
}

resource "aws_glue_catalog_database" "iceberg_db" {
  name = "demo_lake"
}

resource "aws_glue_catalog_table" "iceberg_table" {
  name          = "user_events"
  database_name = aws_glue_catalog_database.iceberg_db.name
  table_type    = "EXTERNAL_TABLE"

  parameters = {
    "table_type" = "ICEBERG"
    "format"     = "parquet"
    "EXTERNAL"   = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${aws_s3_bucket.datalake.bucket}/data/iceberg-demo/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      name                  = "ParquetHiveSerDe"
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "user_id"
      type = "string"
    }
    columns {
      name = "event_type"
      type = "string"
    }
    columns {
      name = "timestamp"
      type = "timestamp"
    }
    columns {
      name = "region"
      type = "string"
    }
    columns {
      name = "amount"
      type = "float"
    }
  }

  partition_keys {
    name = "region"
    type = "string"
  }
}