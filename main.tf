terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.41"
    }
  }
  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "eu-west-1"
}


variable "iam_policy_arn" {
  description = "IAM Policy to be attached to role"
  type        = list(string)
  default = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMFullAccess",
    "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
  ]
}

resource "aws_iam_role" "go-lambda-role" {
  name                = "go-lambda-role"
  managed_policy_arns = var.iam_policy_arn
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = "sts:AssumeRole"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}


resource "null_resource" "go-build" {
  triggers = {
    always_run = "${timestamp()}"
  }

  provisioner "local-exec" {
    command = "GOOS=linux go build"
  }
}

data "archive_file" "go-lambda-zip" {
  type        = "zip"
  source_file = "go-lambda"
  output_path = "lambda.zip"

  depends_on = [
    null_resource.go-build
  ]
}

resource "aws_lambda_function" "go-lambda" {
  filename         = "lambda.zip"
  source_code_hash = data.archive_file.go-lambda-zip.output_base64sha256
  function_name    = "go-lambda"
  role             = aws_iam_role.go-lambda-role.arn
  description      = "go-lambda"
  handler          = "go-lambda"
  runtime          = "go1.x"
  timeout          = 10
}


resource "aws_cloudwatch_log_group" "go-log-group" {
  name              = "/aws/lambda/${aws_lambda_function.go-lambda.function_name}"
  retention_in_days = 1
}
