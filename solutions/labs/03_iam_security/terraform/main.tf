# Hands-On: Writing your first role and policy
resource "aws_iam_policy" "cost_explorer_eu_only" {
  name        = "CostExplorerEuOnly"
  description = "Allows access to AWS Cost Explorer only in eu-central-1"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ce:Get*",
          "ce:List*"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:RequestedRegion" = "eu-central-1"
          }
        }
      }
    ]
  })
}

resource "aws_iam_user" "cost_explorer_user" {
  name = "cost-explorer-user"
}

resource "aws_iam_user_policy_attachment" "attach_cost_explorer" {
  user       = aws_iam_user.cost_explorer_user.name
  policy_arn = aws_iam_policy.cost_explorer_eu_only.arn
}

resource "aws_iam_access_key" "cost_explorer_user_key" {
  user = aws_iam_user.cost_explorer_user.name
}

# Hands-On Lab – Creating Identity Center Access Across Accounts
resource "aws_identitystore_group" "admin" {
  display_name      = "Admin"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group" "ccc" {
  display_name      = "CloudCompetenceCenter"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_group" "dev" {
  display_name      = "Developer"
  identity_store_id = local.identity_store_id
}

resource "aws_identitystore_user" "me" {
  user_name         = "myuser"
  identity_store_id = local.identity_store_id
  display_name      = "My User"
  name {
    given_name  = "My"
    family_name = "User"
  }
  emails {
    value = "myuser@example.com"
  }
}

resource "aws_identitystore_group_membership" "admin_member" {
  group_id          = aws_identitystore_group.admin.group_id
  identity_store_id = local.identity_store_id
  member_id         = aws_identitystore_user.me.user_id
}

resource "aws_identitystore_group_membership" "ccc_member" {
  group_id          = aws_identitystore_group.ccc.group_id
  identity_store_id = local.identity_store_id
  member_id         = aws_identitystore_user.me.user_id
}

resource "aws_identitystore_group_membership" "dev_member" {
  group_id          = aws_identitystore_group.dev.group_id
  identity_store_id = local.identity_store_id
  member_id         = aws_identitystore_user.me.user_id
}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdminRole"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT1H"

}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
}

resource "aws_ssoadmin_permission_set" "ccc" {
  name             = "CloudCompetenceCenterRole"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT2H"
}

resource "aws_ssoadmin_managed_policy_attachment" "ccc" {
  instance_arn       = local.sso_instance_arn
  managed_policy_arn = "arn:aws:iam::aws:policy/PowerUserAccess"
  permission_set_arn = aws_ssoadmin_permission_set.ccc.arn
}

resource "aws_ssoadmin_permission_set" "dev" {
  name             = "DeveloperRole"
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

data "aws_iam_policy_document" "dev" {
  statement {
    sid = "1"

    actions = [
      "ec2:*",
      "s3:*",
      "athena:*",
      "lambda:*",
      "sagemaker:*"
    ]

    resources = ["*"]
  }
}

resource "aws_ssoadmin_permission_set_inline_policy" "example" {
  inline_policy      = data.aws_iam_policy_document.dev.json
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.dev.arn
}


# Admin - all accounts
resource "aws_ssoadmin_account_assignment" "admin_assign" {
  for_each = toset(local.all_account_ids)

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  principal_id       = aws_identitystore_group.admin.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

resource "aws_ssoadmin_account_assignment" "ccc_assign" {
  for_each = toset(local.all_account_ids)

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.ccc.arn
  principal_id       = aws_identitystore_group.ccc.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

# Dev - only sandbox accounts
resource "aws_ssoadmin_account_assignment" "dev_assign" {
  for_each = { for k, v in aws_organizations_account.sandbox_accounts : k => v.id }

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.dev.arn
  principal_id       = aws_identitystore_group.dev.group_id
  principal_type     = "GROUP"
  target_id          = each.value
  target_type        = "AWS_ACCOUNT"
}

# Hands-On Lab – Deny All Regions Except eu-central-1 and eu-central-2
resource "aws_organizations_policy" "deny_regions" {
  name        = "DenyRegions"
  description = "Deny regions"
  content     = jsonencode({
   "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyAllRegionsExceptEU",
      "Effect": "Deny",
      "Action": "*",
      "Resource": "*",
      "Condition": {
        "StringNotEquals": {
          "aws:RequestedRegion": [
            "eu-central-1",
            "eu-central-2"
          ]
        }
      }
    }
  ]
  })
  type = "SERVICE_CONTROL_POLICY"
}

# Hands-On Lab – Create a Cognito User Pool
resource "aws_cognito_user_pool" "main" {
  name = "main-user-pool"

  mfa_configuration       = "ON"
  auto_verified_attributes = ["email", "phone_number"]
  username_attributes      = ["email"]

  sms_configuration {
    external_id    = "MyExternalId"  # Replace with any unique string
    sns_caller_arn = aws_iam_role.cognito_sns_role.arn
  }

  sms_authentication_message = "Your authentication code is {####}"

  schema {
    name                     = "name"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true
  }

  schema {
    name                     = "email"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true
  }

  schema {
    name                     = "phone_number"
    attribute_data_type      = "String"
    developer_only_attribute = false
    mutable                  = true
    required                 = true
  }

  email_configuration {
    email_sending_account = "COGNITO_DEFAULT"
  }

  verification_message_template {
    default_email_option = "CONFIRM_WITH_CODE"
  }
}

# IAM Role for SNS access (required for SMS MFA)
resource "aws_iam_role" "cognito_sns_role" {
  name = "CognitoSNSRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "cognito-idp.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "cognito_sns_policy" {
  name = "CognitoSNSPolicy"
  role = aws_iam_role.cognito_sns_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "sns:Publish"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_cognito_user_pool_client" "web_client" {
  name         = "web-client"
  user_pool_id = aws_cognito_user_pool.main.id

  generate_secret = true

  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_scopes                = ["email", "openid", "profile"]
  supported_identity_providers        = ["COGNITO"]

  callback_urls = ["https://example.com/callback"]
  logout_urls   = ["https://example.com/signout"]
}

resource "aws_cognito_user_pool_domain" "main_domain" {
  domain       = "your-unique-prefix-hosted-ui" # Must be globally unique
  user_pool_id = aws_cognito_user_pool.main.id
}

# Hands-On Lab – Create an Organization Trail

resource "aws_s3_bucket" "org_cloudtrail_logs" {
  provider = aws.security
  bucket_prefix = "org-cloudtrail-logs"

  force_destroy = true
}

resource "aws_s3_bucket_policy" "allow_cloudtrail_write" {
  provider = aws.security
  bucket   = aws_s3_bucket.org_cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:GetBucketAcl",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.org_cloudtrail_logs.id}"
      },
      {
        Sid       = "AWSCloudTrailWrite",
        Effect    = "Allow",
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        },
        Action    = "s3:PutObject",
        Resource  = "arn:aws:s3:::${aws_s3_bucket.org_cloudtrail_logs.id}/AWSLogs/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "org_trail" {
  name                          = "org-cloudtrail"
  s3_bucket_name                = aws_s3_bucket.org_cloudtrail_logs.bucket
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  is_organization_trail         = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    # This logs all management API calls
    data_resource {
      type = "AWS::S3::Object"
      values = ["arn:aws:s3:::"] # optional, more for data events
    }
  }

  depends_on = [
    aws_s3_bucket_policy.allow_cloudtrail_write
  ]
}

# Hands-On – Create and Use a KMS Key

resource "aws_kms_key" "key" {
  description             = "My customer-managed symmetric KMS key"
  enable_key_rotation     = true
  deletion_window_in_days = 30  # Optional, default is 30 days
  key_usage              = "ENCRYPT_DECRYPT"
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
  
  tags = {
    Name = "MyKMSKey"
  }
}

# Optional: create an alias for easier referencing
resource "aws_kms_alias" "key" {
  name          = "alias/my-key-alias"
  target_key_id = aws_kms_key.key.key_id
}