provider "aws" {
  region = "eu-west-1"
}

# Role that only the main branch of acme/webapp can assume,
# allowed to push images to a single ECR repository.
module "github_oidc" {
  source = "../.."

  role_name = "github-actions-webapp"
  subjects  = ["repo:acme/webapp:ref:refs/heads/main"]

  inline_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "ecr:GetAuthorizationToken"
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart",
        ]
        Resource = "arn:aws:ecr:eu-west-1:123456789012:repository/webapp"
      },
    ]
  })

  tags = {
    ManagedBy = "terraform"
  }
}

output "role_arn" {
  value = module.github_oidc.role_arn
}
