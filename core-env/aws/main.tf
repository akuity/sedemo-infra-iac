#
# Base IAM Setup for Human access
#

import {
  to = aws_iam_role.demo_role
  id = var.limited_assumed_role
}

resource "aws_iam_role" "demo_role" {
  name        = var.limited_assumed_role
  description = "Role used by SE team, with permission to be assumed by IT assigned SSO Role."

  assume_role_policy = templatefile(
    "${path.module}/templates/operator_role.json.tpl",
    {
      SSO_USER_LIST = tostring(jsonencode(local.sso_user_list))
    }
  )

  tags = var.common_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "demo_policy" {
  name = "${var.limited_assumed_role}-policy"

  description = "Policy for the admin team for EKS clusters"

  policy = templatefile(
    "${path.module}/templates/operator_policy.json.tpl",
    {

    }
  )

  tags = var.common_tags

}

resource "aws_iam_role_policy_attachment" "fe_eks" {
  role       = aws_iam_role.demo_role.name
  policy_arn = aws_iam_policy.demo_policy.arn
}


#
#. Allow our GHA pipelines to do stuff in AWS too
#

# OIDC provider allows GHA to connect to our account.
resource "aws_iam_openid_connect_provider" "gha" {

  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = var.common_tags
}

# Specific role for GHA via OIDC to assume (can also be assumed by team)
resource "aws_iam_role" "demo_gha_role" {
  name        = var.priviledged_assumed_role
  description = "Role used by GHA pipelines"

  assume_role_policy = templatefile(
    "${path.module}/templates/pipeline_role.json.tpl",
    {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.id,
      SSO_USER_LIST  = tostring(jsonencode(local.sso_user_list))
    }
  )

  tags = var.common_tags
  lifecycle {
    create_before_destroy = true
  }
}

#give the assumed role for GHA or team some permissions
resource "aws_iam_policy" "demo_gha_policy" {
  name = "${var.priviledged_assumed_role}-policy"

  description = "Policy for the admin team for EKS clusters"

  policy = templatefile(
    "${path.module}/templates/pipeline_policy.json.tpl",
    {

    }
  )

  tags = var.common_tags

}

resource "aws_iam_role_policy_attachment" "gha_attachment" {
  role       = aws_iam_role.demo_gha_role.name
  policy_arn = aws_iam_policy.demo_gha_policy.arn
}



#
# Secrets Manager for ESO
#

resource "aws_iam_policy" "demo_secrets_policy" {
  name        = "sedemo-secrets-access-from-eks"
  description = "Policy to grant demo cluster access to secrets via ESO"

  policy = templatefile(
    "${path.module}/templates/secrets_policy.json.tpl",
    {
      AWS_ACCOUNT_ID = data.aws_caller_identity.current.id
    }
  )

  tags = var.common_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "secrets_role" {
  name        = "sedemo-secrets-access-from-eks"
  description = "Role grants access to secrets policy for ESO"

  assume_role_policy = templatefile(
    "${path.module}/templates/secrets_role.json.tpl",
    {

    }
  )

  tags = var.common_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "secrets_attachment" {
  role       = aws_iam_role.secrets_role.name
  policy_arn = aws_iam_policy.demo_secrets_policy.arn
}