provider "aws" {
  region = var.aws_region
}

# DynamoDB table for tracking posted jobs
resource "aws_dynamodb_table" "linkedin_jobs_table" {
  name         = "LinkedInJobsPosted"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "job_id"

  attribute {
    name = "job_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  tags = {
    Name        = "linkedin-jobs-table"
    Environment = "production"
  }
}

# Create a ZIP file of the lambda code
data "archive_file" "lambda_zip" {
  type        = "zip"
  output_path = "${path.module}/linkedin_jobs_lambda.zip"
  
  source {
    content  = file("${path.module}/../main.py")
    filename = "main.py"
  }
  
  source {
    content  = file("${path.module}/../config.json")
    filename = "config.json"
  }
}

# IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "linkedin_jobs_lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Lambda permission policy
resource "aws_iam_policy" "lambda_policy" {
  name        = "linkedin_jobs_lambda_policy"
  description = "Policy for LinkedIn Jobs Lambda function"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem",
          "dynamodb:Query",
          "dynamodb:Scan"
        ]
        Effect   = "Allow"
        Resource = aws_dynamodb_table.linkedin_jobs_table.arn
      },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# Lambda layer for dependencies
resource "aws_lambda_layer_version" "dependencies_layer" {
  layer_name = "linkedin-jobs-dependencies"
  description = "Dependencies for LinkedIn Jobs Lambda"
  
  filename = "${path.module}/lambda_layer.zip"
  
  compatible_runtimes = ["python3.9"]
}

# Lambda function
resource "aws_lambda_function" "linkedin_jobs_function" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = "linkedin-jobs-discord-bot"
  role          = aws_iam_role.lambda_role.arn
  handler       = "main.lambda_handler"
  runtime       = "python3.9"
  timeout       = 60
  memory_size   = 128
  
  layers        = [aws_lambda_layer_version.dependencies_layer.arn]

  environment {
    variables = {
      STOCKHOLM_WEBHOOK_URL = var.stockholm_webhook_url
      OSLO_WEBHOOK_URL      = var.oslo_webhook_url
    }
  }
  
  depends_on = [
    aws_iam_role_policy_attachment.lambda_policy_attachment,
    data.archive_file.lambda_zip
  ]
}

# CloudWatch event rule (scheduler)
resource "aws_cloudwatch_event_rule" "daily_job_check" {
  name                = "linkedin-jobs-daily-check"
  description         = "Trigger LinkedIn jobs check daily"
  schedule_expression = "cron(0 9 * * ? *)"
}

# CloudWatch event target
resource "aws_cloudwatch_event_target" "check_jobs_event_target" {
  rule      = aws_cloudwatch_event_rule.daily_job_check.name
  target_id = "LinkedInJobsFunction"
  arn       = aws_lambda_function.linkedin_jobs_function.arn
}

# Lambda permission for CloudWatch
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.linkedin_jobs_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily_job_check.arn
}