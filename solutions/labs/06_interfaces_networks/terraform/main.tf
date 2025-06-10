# Hands-On – Distribute Your S3 Website via CloudFront (with OAC)

#############################
# Remove this below
#############################

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.website_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "error.html"
  }

}

#############################
# Remove this above
#############################

resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "s3-oac-access"
  description                       = "OAC for S3 bucket access"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name
    origin_id   = "s3-origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  tags = {
    Name = "CloudFrontS3Website"
  }
}

resource "aws_s3_bucket_policy" "cloudfront_policy" {
  bucket = aws_s3_bucket.website_bucket.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AllowCloudFrontOAC",
        Effect    = "Allow",
        Principal = {
          Service = "cloudfront.amazonaws.com"
        },
        Action    = "s3:GetObject",
        Resource  = "${aws_s3_bucket.website_bucket.arn}/*",
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = aws_cloudfront_distribution.s3_distribution.arn
          }
        }
      }
    ]
  })
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}

# Hands-On – Create a Subnet for EC2 (no EC2 yet)

resource "aws_vpc" "shared_vpc" {
  provider             = aws.network
  cidr_block           = "10.100.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "shared-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  provider          = aws.network
  vpc_id            = aws_vpc.shared_vpc.id
  cidr_block        = "10.100.1.0/24"
  availability_zone = "eu-central-1a"

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  provider          = aws.network
  vpc_id            = aws_vpc.shared_vpc.id
  cidr_block        = "10.100.2.0/24"
  availability_zone = "eu-central-1b"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  provider = aws.network
  vpc_id   = aws_vpc.shared_vpc.id

  tags = {
    Name = "shared-vpc-igw"
  }
}

resource "aws_route_table" "public_rt" {
  provider = aws.network
  vpc_id   = aws_vpc.shared_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-route-table"
  }
}

# Associate public subnet to public route table
resource "aws_route_table_association" "public_assoc" {
  provider       = aws.network
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Hands-On – Security Group for SSH Only

resource "aws_security_group" "ssh_only" {
  name        = "ssh-only"
  description = "Allow SSH from my IP"
  vpc_id      = aws_vpc.main.id

  ingress {
    description      = "SSH from my IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.my_ip.body)}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ssh-only"
  }
}

resource "aws_instance" "ssh_test" {
  ami           = "ami-0faab6bdbac9486fb" # Amazon Linux 2023 in eu-central-1
  instance_type = "t3.nano"
  key_name      = "my-keypair" # Replace with your key pair
  subnet_id     = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ssh_only.id]

  tags = {
    Name = "SSH-Test-Instance"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "eu-central-1a"
  map_public_ip_on_launch = true
}


resource "aws_route_table_association" "assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Hands-On – Central VPC Setup in `network` Account

resource "aws_ram_resource_share" "vpc_share" {
  provider       = aws.network
  name                      = "Shared-VPC"
  allow_external_principals = false
}

resource "aws_ram_principal_association" "sandbox_accounts" {
  provider       = aws.network
  for_each = { for k, v in aws_organizations_account.sandbox_accounts : k => v.id }

  principal          = each.value
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

resource "aws_ram_resource_association" "public_subnet_share" {
  provider       = aws.network
  resource_arn       = aws_subnet.public_subnet.arn
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

resource "aws_ram_resource_association" "private_subnet_share" {
  provider       = aws.network
  resource_arn       = aws_subnet.private_subnet.arn
  resource_share_arn = aws_ram_resource_share.vpc_share.arn
}

# Hands-On – Auto Scaling + Load Balancer in Shared Network



resource "aws_lb" "sandbox_alb" {
  name               = "sandbox-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = data.aws_subnets.example.ids
  tags = {
    Name = "sandbox-alb"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn  = aws_lb.sandbox_alb.arn
  port               = 80
  protocol           = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sandbox_tg.arn
  }
}

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Allow HTTP inbound to ALB"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_lb_target_group" "sandbox_tg" {
  name     = "sandbox-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 3
    unhealthy_threshold = 3
  }

  tags = {
    Name = "sandbox-tg"
  }
}



resource "aws_autoscaling_attachment" "asg_tg_attachment" {
  autoscaling_group_name = aws_autoscaling_group.example.name
  lb_target_group_arn    = aws_lb_target_group.sandbox_tg.arn
}

resource "aws_security_group" "http_ssh_sg" {

  name        = "http-ssh-sg"
  description = "Allow SSH and HTTP"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "Hello from sandbox test ASG" > /var/www/html/index.html
              EOF
  )

   vpc_security_group_ids = [aws_security_group.http_ssh_sg.id] # This resource is not new but this line is appended. Keep the original
}

# Hands-On – My First REST API (w/ Required Query Params)

resource "aws_api_gateway_rest_api" "log_api" {
  name        = "log-api"
  description = "API Gateway for logging via Lambda"
}

resource "aws_api_gateway_resource" "log_resource" {
  rest_api_id = aws_api_gateway_rest_api.log_api.id
  parent_id   = aws_api_gateway_rest_api.log_api.root_resource_id
  path_part   = "log"
}

resource "aws_api_gateway_method" "get_log" {
  rest_api_id   = aws_api_gateway_rest_api.log_api.id
  resource_id   = aws_api_gateway_resource.log_resource.id
  http_method   = "GET"
  authorization = "NONE"

  request_parameters = {
    "method.request.querystring.user" = true
    "method.request.querystring.msg"  = true
  }

  request_validator_id = aws_api_gateway_request_validator.query_validator.id
}

resource "aws_api_gateway_request_validator" "query_validator" {
  name                             = "query-string-validator"
  rest_api_id                     = aws_api_gateway_rest_api.log_api.id
  validate_request_parameters      = true
  validate_request_body            = false
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.log_api.id
  resource_id             = aws_api_gateway_resource.log_resource.id
  http_method             = aws_api_gateway_method.get_log.http_method
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.logger.invoke_arn
}

resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.logger.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.log_api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "deployment" {
  depends_on = [
    aws_api_gateway_integration.lambda_integration
  ]

  rest_api_id = aws_api_gateway_rest_api.log_api.id
}

resource "aws_api_gateway_stage" "example" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.log_api.id
  stage_name    = "dev"
}

# Hands-On – SNS Alert on Root User Usage
# TODO