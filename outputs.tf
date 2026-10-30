output "role_arn" {
  description = "ARN of the IAM role. Use it as `role-to-assume` in aws-actions/configure-aws-credentials."
  value       = aws_iam_role.this.arn
}

output "role_name" {
  description = "Name of the IAM role."
  value       = aws_iam_role.this.name
}

output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider used by the role."
  value       = local.oidc_provider_arn
}
