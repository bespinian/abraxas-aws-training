locals {
  all_account_ids = concat(
    [for acct in aws_organizations_account.management_accounts : acct.id],
    [for acct in aws_organizations_account.sandbox_accounts : acct.id]
  )
  identity_store_id  = tolist(data.aws_ssoadmin_instances.sso.identity_store_ids)[0]
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.sso.arns)[0]
}