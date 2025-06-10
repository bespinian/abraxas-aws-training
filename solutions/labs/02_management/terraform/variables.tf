variable "it_admins" {
  type = list(string)
}

variable "management_accounts" {
    type = list(string)
}

variable "sandbox_accounts" {
    type = map(string)
}

variable "org_owner_mail" {
    type = string
}