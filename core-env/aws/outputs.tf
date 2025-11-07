output "demo_operator_role_arn" {
  value = aws_iam_role.demo_role.arn
}
output "demo_pipeline_role_arn" {
  value = aws_iam_role.demo_gha_role.arn
}
