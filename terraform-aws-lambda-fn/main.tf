terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

locals {
  # Merge default + user tags
  tags = merge(
    {
      "Terraform" = "true"
      "Module"    = "lambda"
    },
    var.tags
  )

  log_group_name = "/aws/lambda/${var.function_name}"
}

# IAM role for Lambda
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "this" {
  name               = coalesce(var.role_name, "${var.function_name}-role")
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
  tags               = local.tags
}

# Attach basic execution policy (writes to CloudWatch Logs)
resource "aws_iam_role_policy_attachment" "basic_exec" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Optional: VPC execution policy if vpc_config provided
data "aws_partition" "current" {}

resource "aws_iam_role_policy_attachment" "vpc_exec" {
  count      = var.vpc_config == null ? 0 : 1
  role       = aws_iam_role.this.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# CloudWatch log group (optional but recommended for retention control)
resource "aws_cloudwatch_log_group" "this" {
  name              = local.log_group_name
  retention_in_days = var.log_retention_days
  tags              = local.tags
}

# The Lambda function
resource "aws_lambda_function" "this" {
  function_name = var.function_name
  filename      = var.filename
  handler       = var.handler
  runtime       = var.runtime

  role = var.role_arn != null ? var.role_arn : aws_iam_role.this.arn

  # Ensures updates when ZIP changes
  source_code_hash = filebase64sha256(var.filename)

  description = var.description

  timeout       = var.timeout
  memory_size   = var.memory_size
  architectures = var.architectures

  # Env vars, if any
  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  # Layers, if provided
  layers = var.layers

  # Dead-letter queue config (ARN)
  dynamic "dead_letter_config" {
    for_each = var.dead_letter_target_arn == null ? [] : [var.dead_letter_target_arn]
    content {
      target_arn = dead_letter_config.value
    }
  }

  # VPC config, if provided
  dynamic "vpc_config" {
    for_each = var.vpc_config == null ? [] : [var.vpc_config]
    content {
      security_group_ids = vpc_config.value.security_group_ids
      subnet_ids         = vpc_config.value.subnet_ids
    }
  }

  # Ephemeral storage size (MB)
  dynamic "ephemeral_storage" {
    for_each = var.ephemeral_storage_size_mb == null ? [] : [var.ephemeral_storage_size_mb]
    content {
      size = ephemeral_storage.value
    }
  }

  publish = var.publish

  # Reserved concurrency (null = unreserved)
  reserved_concurrent_executions = var.reserved_concurrent_executions

  tracing_config {
    mode = var.tracing_mode
  }

  package_type = "Zip"

  tags = local.tags

  depends_on = [
    aws_iam_role_policy_attachment.basic_exec,
    aws_cloudwatch_log_group.this
  ]
}

# Optional: permission to allow CloudWatch Logs creation if needed (mostly handled by policy above)
