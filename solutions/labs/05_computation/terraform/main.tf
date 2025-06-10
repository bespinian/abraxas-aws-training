#  Hands-On – My First EC2 Instance

resource "aws_instance" "my_ec2" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.nano"  # very lightweight
  associate_public_ip_address = true  # required for Elastic IP

  # Optional: Add a name tag
  tags = {
    Name = "MyFirstEC2"
  }
}

resource "aws_ebs_volume" "extra_volume" {
  availability_zone = aws_instance.my_ec2.availability_zone
  size              = 5  # in GB
  type              = "gp3"

  tags = {
    Name = "ExtraVolume"
  }
}

resource "aws_volume_attachment" "ebs_attached" {
  device_name = "/dev/sdf"
  volume_id   = aws_ebs_volume.extra_volume.id
  instance_id = aws_instance.my_ec2.id
}

resource "aws_eip" "my_eip" {
  instance = aws_instance.my_ec2.id
  domain   = "vpc"
}

### Hands-On – Auto Scaling Group

resource "aws_launch_template" "example" {
  name_prefix   = "asg-launch-template-"
  image_id      = data.aws_ami.amazon_linux.id
  instance_type = "t3.micro"

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "ASGInstance"
    }
  }
}

resource "aws_autoscaling_group" "example" {
  name                      = "example-asg"
  desired_capacity          = 2
  max_size                  = 4
  min_size                  = 1
  vpc_zone_identifier       = [data.aws_subnets.example.ids[0]]  # pick a subnet
  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.example.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "AutoScaledInstance"
    propagate_at_launch = true
  }
}

# Hands-On – React to DynamoDB Streams with Lambda & Hands-On – Write DynamoDB Entry to S3 as CSV

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

  stream_enabled   = true # IMPORTANT: Don't recopy this, just append the changes and work with the existing dynamodb
  stream_view_type = "NEW_IMAGE"

  tags = {
    Name = "usertable"
    Env  = "Dev"
  }
}

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

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    Name = "usertable"
    Env  = "Dev"
  }
}

resource "aws_iam_role" "lambda_exec_role" {
  name = "lambda_exec_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "dynamodb_stream_access" {
  name = "dynamodb_stream_access"
  role = aws_iam_role.lambda_exec_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "dynamodb:DescribeStream",
        "dynamodb:GetRecords",
        "dynamodb:GetShardIterator",
        "dynamodb:ListStreams"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_lambda_function" "logger" {
  filename         = "lambda_function_payload.zip"
  function_name    = "logger"
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  role             = aws_iam_role.lambda_exec_role.arn
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.csv_dump_bucket.bucket
    }
  }
}

resource "aws_s3_bucket" "csv_dump_bucket" {
  bucket_prefix = "dynamodb-to-s3-csv-bucket-demo" 
}

resource "aws_iam_policy" "lambda_s3_policy" {
  name = "LambdaS3PutObjectPolicy"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:PutObject"],
      Resource = "${aws_s3_bucket.csv_dump_bucket.arn}/*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_access" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = aws_iam_policy.lambda_s3_policy.arn
}

# Hands-On – My First Step Function

resource "aws_iam_role" "step_function_role" {
  name = "StepFunctionExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "states.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "step_function_lambda_access" {
  name = "InvokeLambda"
  role = aws_iam_role.step_function_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "lambda:InvokeFunction",
        Resource = aws_lambda_function.logger.arn
      }
    ]
  })
}

resource "aws_sfn_state_machine" "simple_state_machine" {
  name     = "WaitThenLambda"
  role_arn = aws_iam_role.step_function_role.arn

  definition = jsonencode({
    Comment = "A simple state machine that waits and invokes Lambda.",
    StartAt = "Wait5Seconds",
    States = {
      Wait5Seconds = {
        Type     = "Wait",
        Seconds  = 5,
        Next     = "InvokeLambda"
      },
      InvokeLambda = {
        Type     = "Task",
        Resource = aws_lambda_function.logger.arn,
        End      = true
      }
    }
  })
}
