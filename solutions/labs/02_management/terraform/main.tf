terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-central-1"
}

#Hands-On Lab - Budgets
resource "aws_budgets_budget" "org_budget" {
  name              = "Training-Budget"
  budget_type       = "COST"
  limit_amount      = "10"
  limit_unit        = "USD"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    notification_type          = "ACTUAL"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    subscriber_email_addresses = var.it_admins
  }
}

#Hands-On Lab – Organizations
resource "aws_organizations_organization" "org" {
  feature_set = "ALL"
  aws_service_access_principals = [
    "sso.amazonaws.com",
    "cloudtrail.amazonaws.com",
    "ram.amazonaws.com",
  ]
  enabled_policy_types = [
    "RESOURCE_CONTROL_POLICY"
  ]
}

# Create Organizational Units
resource "aws_organizations_organizational_unit" "management" {
  name      = "management"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "sandbox"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create Accounts under 'management'
resource "aws_organizations_account" "management_accounts" {
  for_each  = toset(var.management_accounts)
  name      = each.value
  email     = "${each.value}+${var.org_owner_mail}"
  parent_id = aws_organizations_organizational_unit.management.id
}

resource "aws_organizations_account" "sandbox_accounts" {
  for_each  = var.sandbox_accounts
  name      = each.key
  email     = each.value
  parent_id = aws_organizations_organizational_unit.sandbox.id
}
