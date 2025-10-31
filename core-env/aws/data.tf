data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  sso_user_list = [for username in var.email_usernames : "arn:aws:sts::${data.aws_caller_identity.current.account_id}:assumed-role/${var.sso_iam_role}/${username}@akuity.io"]
}