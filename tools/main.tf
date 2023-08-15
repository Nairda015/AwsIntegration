locals {
  name_prefix = "${var.aws_owner_login}-${var.env_prefix}-${var.app_name}"
}

# ECR Repository
module "ecr" {
  enabled = var.enable_ecr
  source  = "cloudposse/ecr/aws"
  version = "0.38.0"

  namespace               = var.aws_owner_login
  stage                   = var.env_prefix
  name                    = var.app_name
  force_delete            = true
  image_tag_mutability    = "MUTABLE"
  enable_lifecycle_policy = false
  tags                    = { "Name" = "${local.name_prefix}-ecr" }
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
  iam_role_policy_arns  = [
    aws_iam_policy.ecr_login_policy.arn,
    aws_iam_policy.ecr_push_policy.arn
  ]

  tags = { "Name" = "${local.name_prefix}-oidc-github" }
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
          "ecr:GetAuthorizationToken",
          "sts:GetServiceBearerToken"
        ],
        "Resource" : "*"
      }
    ]
  })
}
resource "aws_iam_policy" "ecr_push_policy" {
  name        = "ECRPushPolicy"
  description = "ECR push policy"

  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "AllowPush",
        "Effect" : "Allow",
        "Action" : [
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ],
        "Resource" : module.ecr.repository_arn
      }
    ]
  })
}


# Github Actions Secrets
resource "github_actions_secret" "aws_owner" {
  repository      = var.repo_name
  secret_name     = "AWS_OWNER"
  plaintext_value = var.aws_owner_login
}
resource "github_actions_secret" "role_to_assume_arn" {
  repository      = var.repo_name
  secret_name     = "ROLE_TO_ASSUME_ARN"
  plaintext_value = module.oidc-github.iam_role_arn
}
resource "github_actions_secret" "ecr_repository_name" {
  repository      = var.repo_name
  secret_name     = "ECR_REPOSITORY_NAME"
  plaintext_value = module.ecr.repository_name
}


# Lambda From ECR
module "lambda_function" {
  source  = "terraform-aws-modules/lambda/aws"
  count   = var.enable_lambda ? 1 : 0
  version = "5.3.0"

  function_name  = "${var.aws_owner_login}-${var.app_name}"
  create_package = false
  image_uri      = "${module.ecr.repository_url}:001"
  package_type   = "Image"

  create_lambda_function_url = true
  authorization_type         = "NONE"
}

module "lambda_empty_function" {
  count   = var.enable_sqs_lambda ? 1 : 0
  source  = "terraform-aws-modules/lambda/aws"
  version = "5.3.0"

  function_name  = "${var.aws_owner_login}-lambda-empty-function"
  create_package = false
  image_uri      = "${module.ecr.repository_url}:lambda-empty-function-latest"
  package_type   = "Image"
  memory_size    = 256
  timeout        = 10

  attach_policy = true
  policy        = aws_iam_policy.policy_lambda_empty_function.arn

  tags = { "Name" = "${local.name_prefix}-lambda-empty-function" }
}
resource "aws_iam_policy" "policy_lambda_empty_function" {
  name = "${local.name_prefix}-lambda-empty-function-policy"
  path = "/"

  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Action = [
          "sqs:*",
          "aoss:*",
          "ssm:*",
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}