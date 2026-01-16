{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action" : [
        "s3:CreateBucket",
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Effect" : "Allow",
      "Resource" : "*"
    },
    {
      "Action" : [
        "secretsmanager:ListSecrets",
        "secretsmanager:BatchGetSecretValue"
      ],
      "Effect" : "Allow",
      "Resource" : "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetResourcePolicy",
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
        "secretsmanager:ListSecretVersionIds"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-west-2:${AWS_ACCOUNT_ID}:secret:kargo-*"
      ]
    }
  ]
}
