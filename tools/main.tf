locals {
  name-prefix   = "${var.aws_owner_login}-${var.env_prefix}-${var.app_name}"
}

# ECR Repository
module "ecr" {
  enabled                 = var.enable_ecr
  source                  = "cloudposse/ecr/aws"
  version                 = "0.38.0"
  namespace               = "pgs"
  stage                   = var.env_prefix
  name                    = var.app_name
  //principals_full_access  = [module.oidc-github.iam_role_arn]
  //principals_lambda       = [module.oidc-github.iam_role_arn]
  force_delete            = true
  enable_lifecycle_policy = false
  tags                    = { "Name" = "${local.name-prefix}-ecr" }
}


# Github Actions Role To Assume
module "oidc-github" {
  enabled = var.enable_github
  source  = "unfunco/oidc-github/aws"
  version = "1.5.2"

  attach_admin_policy   = false
  create_oidc_provider  = true
  force_detach_policies = true
  github_repositories   = ["${var.repo_owner}/${var.repo_name}"]
  iam_role_name         = "ecr-github-integration"
  iam_role_policy_arns = [
    aws_iam_policy.ecr_login_policy.arn,
    aws_iam_policy.ecr_push_policy.arn
  ]

  tags = { "Name" = "${local.name-prefix}-oidc-github" }
}
resource "aws_iam_policy" "ecr_login_policy" {
  name        = "ECRLoginPolicy"
  description = "ECR login policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "GetAuthorizationToken",
        "Effect" : "Allow",
        "Action" : [
          "ecr-public:GetAuthorizationToken",
          "sts:GetServiceBearerToken"
        ],
        "Resource" : "*"
      }
    ]
  })
}
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "ECRPushPolicy"
  description = "ECR write access policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowPush",
        "Effect" : "Allow",
        "Action" : [
          "ecr-public:BatchCheckLayerAvailability",
          "ecr-public:CompleteLayerUpload",
          "ecr-public:InitiateLayerUpload",
          "ecr-public:PutImage",
          "ecr-public:UploadLayerPart"
        ],
        "Resource" : module.ecr.repository_arn
      }
    ]
  })
}


# Github Actions Secrets
resource "github_actions_secret" "aws_owner" {
  repository       = var.repo_name
  secret_name      = "AWS_OWNER"
  plaintext_value  = var.aws_owner_login
}
resource "github_actions_secret" "role_to_assume_arn" {
  repository       = var.repo_name
  secret_name      = "ROLE_TO_ASSUME_ARN"
  plaintext_value  = module.oidc-github.iam_role_arn
}
resource "github_actions_secret" "ecr_repository_name" {
  repository       = var.repo_name
  secret_name      = "ECR_REPOSITORY_NAME"
  plaintext_value  = module.ecr.repository_name
}

