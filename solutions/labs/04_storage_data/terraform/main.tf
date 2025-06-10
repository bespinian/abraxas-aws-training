# Hands-On – Create a Lifecycle Rule

resource "aws_s3_bucket" "demo_bucket" {
  bucket_prefix = "demo"
}

resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  bucket = aws_s3_bucket.demo_bucket.id

  rule {
    id     = "move-to-glacier-and-delete"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# Hands-On – Host a Static Website with S3

resource "aws_s3_bucket" "website_bucket" {
  bucket_prefix = "s3-website-demo"
  tags = {
    Name        = "s3-website-demo"
    Environment = "Demo"
  }
}

resource "aws_s3_bucket_public_access_block" "example" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

resource "aws_s3_object" "index" {
  depends_on = [ aws_s3_bucket_public_access_block.example ]
  bucket = aws_s3_bucket.website_bucket.id
  key    = "index.html"
  source = "index.html"  # Make sure this file exists locally
  content_type = "text/html"
}

resource "aws_s3_object" "error" {
  depends_on = [ aws_s3_bucket_public_access_block.example ]
  bucket = aws_s3_bucket.website_bucket.id
  key    = "error.html"
  source = "error.html"  # Make sure this file exists locally
  content_type = "text/html"
}

# Hands-On – Launching an RDS Instance

resource "aws_db_instance" "mysql_instance" {
  identifier            = "my-mysql-instance-simple"
  allocated_storage     = 20
  max_allocated_storage = 50
  storage_type          = "gp3"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.medium"
  multi_az              = false
  publicly_accessible   = true

  username = "admin"
  password = "YourStrongPassw0rd!"

  storage_encrypted       = true
  kms_key_id              = null

  iam_database_authentication_enabled = true

  backup_retention_period = 7
  skip_final_snapshot    = true

  performance_insights_enabled = true
  performance_insights_retention_period = 7

  tags = {
    Name = "My Simple MySQL Instance"
  }
}

# Hands-On – My First DynamoDB Table & Hands-On – My First Secondary Index

resource "aws_dynamodb_table" "usertable" {
  name           = "usertable"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"

  attribute {
    name = "email"
    type = "S"
  }

  attribute {
    name = "name"
    type = "S"
  }

  global_secondary_index {
    name            = "NameIndex"
    hash_key        = "name"
    projection_type = "ALL"
  }

  tags = {
    Name = "usertable"
    Env  = "Dev"
  }
}

# Hands-On – Backup a DynamoDB Table
resource "aws_backup_vault" "my_vault" {
  name        = "my-backup-vault"
  kms_key_arn = aws_kms_key.key.arn

  tags = {
    Name = "BackupVault"
  }
}

resource "aws_backup_plan" "daily_backup" {
  name = "daily-backup-plan"

  rule {
    rule_name         = "daily-backup-rule"
    target_vault_name = aws_backup_vault.my_vault.name
    schedule          = "cron(0 5 * * ? *)"  # daily at 05:00 UTC
    start_window      = 60                  # optional (minutes)
    completion_window = 180                 # optional (minutes)
    lifecycle {
      delete_after = 7  # Retain backups for 7 days
    }
  }
}

resource "aws_backup_selection" "dynamodb_backup" {
  iam_role_arn = aws_iam_role.backup_role.arn
  name         = "dynamodb-table-selection"
  plan_id      = aws_backup_plan.daily_backup.id

  resources = [
    aws_dynamodb_table.usertable.arn
  ]
}

resource "aws_iam_role" "backup_role" {
  name = "aws-backup-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "backup.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "backup_policy" {
  role       = aws_iam_role.backup_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
}