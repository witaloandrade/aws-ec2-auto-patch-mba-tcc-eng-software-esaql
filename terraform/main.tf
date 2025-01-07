## Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "lambda_execution_role"
  assume_role_policy = jsonencode({
    "Version" = "2012-10-17"
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

resource "aws_iam_policy" "lambda_role_policy" {
  policy = templatefile("${path.module}/lambda_role_policy.json", {
    lambda_function_name = aws_lambda_function.patch_instances.function_name,
    accound_id           = data.aws_caller_identity.current.account_id
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_role_policy.arn
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "${path.module}/${local.lambda_function_name}.py"
  output_path = "${path.module}/patch_instances.zip"
}


resource "aws_lambda_function" "patch_instances" {
  filename         = data.archive_file.lambda_function.output_path
  function_name    = local.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "${local.lambda_function_name}.lambda_handler"
  source_code_hash = data.archive_file.lambda_function.output_base64sha256
  runtime          = "python3.8"
  timeout          = 300
  architectures    = ["arm64"]

  environment {
    variables = {
      PATCH_TAG_KEY = "auto-patch"
    }
  }
}

resource "aws_cloudwatch_event_rule" "every_hour" {
  name                = "every_hour"
  description         = "Run Lambda function every hour"
  schedule_expression = "cron(15 * * * ? *)"
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_hour.name
  target_id = local.lambda_function_name
  arn       = aws_lambda_function.patch_instances.arn
}

resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patch_instances.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_hour.arn
}
