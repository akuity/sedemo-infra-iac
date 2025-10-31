# resource "aws_route53_zone" "demo_domain" {
#   name    = var.demo_domain
#   comment = "Please contact eddie.webbinaro@akuity.io with questions"
#   tags = {
#     "Owner" = var.common_tags.owner
#   }
#   lifecycle {
#     prevent_destroy = true
#   }
# }

import {
  to = aws_iam_role.demo_role
  id = var.iac_assumed_role
}

resource "aws_iam_role" "demo_role" {
  name        = var.iac_assumed_role
  description = "Role used by SE team, with permission to be assumed by IT assigned SSO Role."

  assume_role_policy = templatefile(
    "${path.module}/templates/assume_role.json.tpl",
    {
      SSO_USER_LIST   = tostring(jsonencode(local.sso_user_list))
    }
  )

  tags = var.common_tags
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_policy" "demo_policy" {
  name = "${var.iac_assumed_role}-policy"

  description = "Policy for the admin team for EKS clusters"

  policy = templatefile(
    "${path.module}/templates/assume_policy.json.tpl",
    {
      
    }
  )

  tags = var.common_tags

}

resource "aws_iam_role_policy_attachment" "fe_eks" {
  role       = aws_iam_role.demo_role.name
  policy_arn = aws_iam_policy.demo_policy.arn
}