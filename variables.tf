variable "role_name" {
  description = "Name of the IAM role that GitHub Actions will assume."
  type        = string
}

variable "subjects" {
  description = <<-EOT
    GitHub OIDC subjects allowed to assume the role, e.g.
    "repo:my-org/my-repo:ref:refs/heads/main" or
    "repo:my-org/my-repo:environment:production".
    Wildcards are allowed inside a repository ("repo:my-org/my-repo:*"),
    but never across organizations or repositories.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.subjects) > 0
    error_message = "At least one subject is required."
  }

  validation {
    condition = alltrue([
      for s in var.subjects : can(regex("^repo:[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+:.+$", s))
    ])
    error_message = "Each subject must be scoped to one repository: \"repo:<owner>/<repo>:<ref|environment|pull_request|*>\". Wildcards in the owner or repository name are not allowed."
  }
}

variable "create_oidc_provider" {
  description = "Create the GitHub OIDC identity provider. Set to false if the account already has one and pass its ARN in oidc_provider_arn."
  type        = bool
  default     = true
}

variable "oidc_provider_arn" {
  description = "ARN of an existing GitHub OIDC provider. Required when create_oidc_provider is false."
  type        = string
  default     = null
}

variable "managed_policy_arns" {
  description = "Managed IAM policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "inline_policy_json" {
  description = "Optional inline IAM policy (JSON) for the role. Prefer this over broad managed policies to keep least privilege."
  type        = string
  default     = null
}

variable "max_session_duration" {
  description = "Maximum session duration in seconds (3600-43200)."
  type        = number
  default     = 3600

  validation {
    condition     = var.max_session_duration >= 3600 && var.max_session_duration <= 43200
    error_message = "max_session_duration must be between 3600 and 43200 seconds."
  }
}

variable "tags" {
  description = "Tags applied to all resources."
  type        = map(string)
  default     = {}
}
