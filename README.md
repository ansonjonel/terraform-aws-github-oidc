# terraform-aws-github-oidc

[![ci](https://github.com/ansonjonel/terraform-aws-github-oidc/actions/workflows/ci.yml/badge.svg)](https://github.com/ansonjonel/terraform-aws-github-oidc/actions/workflows/ci.yml)

Terraform module that lets **GitHub Actions deploy to AWS without long-lived access keys**, using GitHub's OpenID Connect (OIDC) provider and a least-privilege IAM role.

## Why

Storing `AWS_ACCESS_KEY_ID` / `AWS_SECRET_ACCESS_KEY` as repository secrets means static credentials that never expire and are easy to leak. With OIDC, each workflow run exchanges a short-lived GitHub token for temporary AWS credentials, and the IAM trust policy decides exactly **which repository, branch or environment** may assume the role.

This module:

- Creates the GitHub OIDC identity provider (or reuses an existing one).
- Creates an IAM role whose trust policy pins the audience (`sts.amazonaws.com`) and only allows the subjects you list.
- **Rejects over-broad subjects** such as `repo:*` or `repo:my-org/*` at plan time. A wildcard across repositories is the most common OIDC misconfiguration and lets any repo assume your role.
- Attaches managed and/or inline policies.

## Usage

```hcl
module "github_oidc" {
  source = "github.com/ansonjonel/terraform-aws-github-oidc?ref=v1.0.0"

  role_name = "github-actions-webapp"
  subjects  = [
    "repo:acme/webapp:ref:refs/heads/main",      # pushes to main
    "repo:acme/webapp:environment:production",   # jobs using the production environment
  ]

  inline_policy_json = data.aws_iam_policy_document.deploy.json
}
```

Then in the workflow:

```yaml
permissions:
  id-token: write   # required to request the OIDC token
  contents: read

steps:
  - uses: aws-actions/configure-aws-credentials@v6
    with:
      role-to-assume: arn:aws:iam::123456789012:role/github-actions-webapp
      aws-region: eu-west-1
  - run: aws sts get-caller-identity
```

A full example scoped to pushing images to a single ECR repository is in [`examples/basic`](examples/basic).

An AWS account can only have **one** GitHub OIDC provider. If it already exists, set `create_oidc_provider = false` and pass `oidc_provider_arn`.

## Inputs

| Name | Description | Type | Default |
|---|---|---|---|
| `role_name` | Name of the IAM role. | `string` | — |
| `subjects` | Allowed OIDC subjects, each scoped to one repository. | `list(string)` | — |
| `create_oidc_provider` | Create the GitHub OIDC provider. | `bool` | `true` |
| `oidc_provider_arn` | Existing provider ARN (when not creating one). | `string` | `null` |
| `managed_policy_arns` | Managed policies to attach. | `list(string)` | `[]` |
| `inline_policy_json` | Inline policy document (JSON). | `string` | `null` |
| `max_session_duration` | Max session duration, 3600–43200 s. | `number` | `3600` |
| `tags` | Tags for all resources. | `map(string)` | `{}` |

## Outputs

| Name | Description |
|---|---|
| `role_arn` | Role ARN, for `role-to-assume`. |
| `role_name` | Role name. |
| `oidc_provider_arn` | OIDC provider ARN in use. |

## Testing

Tests use Terraform's native test framework with a **mocked AWS provider**, so they run offline with no AWS account:

```bash
terraform init -backend=false
terraform test
```

They check the trust policy contents, provider reuse, policy attachments, and that wildcard subjects and missing provider ARNs are rejected. CI runs `fmt`, `validate` and `test` on every push.

## Requirements

- Terraform >= 1.7
- AWS provider >= 6.0

## License

MIT
