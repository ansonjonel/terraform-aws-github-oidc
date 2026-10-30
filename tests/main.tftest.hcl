# Runs fully offline: the AWS provider is mocked, no credentials needed.
mock_provider "aws" {}

variables {
  role_name = "gha-deploy"
  subjects  = ["repo:acme/webapp:ref:refs/heads/main"]
}

run "creates_provider_and_scoped_role" {
  command = apply

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 1
    error_message = "The OIDC provider should be created by default."
  }

  assert {
    condition     = aws_iam_openid_connect_provider.github[0].url == "https://token.actions.githubusercontent.com"
    error_message = "Wrong OIDC provider URL."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringLike["token.actions.githubusercontent.com:sub"]
      == ["repo:acme/webapp:ref:refs/heads/main"]
    )
    error_message = "Trust policy must only allow the configured subjects."
  }

  assert {
    condition = (
      jsondecode(aws_iam_role.this.assume_role_policy).Statement[0].Condition.StringEquals["token.actions.githubusercontent.com:aud"]
      == "sts.amazonaws.com"
    )
    error_message = "Trust policy must pin the audience to sts.amazonaws.com."
  }
}

run "reuses_existing_provider" {
  command = apply

  variables {
    create_oidc_provider = false
    oidc_provider_arn    = "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
  }

  assert {
    condition     = length(aws_iam_openid_connect_provider.github) == 0
    error_message = "No provider should be created when reusing an existing one."
  }

  assert {
    condition     = output.oidc_provider_arn == "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
    error_message = "The existing provider ARN should be used."
  }
}

run "attaches_inline_and_managed_policies" {
  command = apply

  variables {
    managed_policy_arns = ["arn:aws:iam::aws:policy/ReadOnlyAccess"]
    inline_policy_json  = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Action\":\"s3:ListBucket\",\"Resource\":\"*\"}]}"
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.managed) == 1 && length(aws_iam_role_policy.inline) == 1
    error_message = "Managed and inline policies should be attached."
  }
}

run "rejects_wildcard_across_repositories" {
  command = plan

  variables {
    subjects = ["repo:*"]
  }

  expect_failures = [var.subjects]
}

run "requires_provider_arn_when_not_creating" {
  command = plan

  variables {
    create_oidc_provider = false
  }

  expect_failures = [aws_iam_role.this]
}
