resource "aws_lambda_function" "lambda_etl_function" {
  role             = var.lambda_access_role_arn
  function_name    = var.lambda_etl_function_name
  filename         = var.lambda_etl_file_path
  runtime          = var.lambda_runtime
  handler          = var.lambda_handler
  source_code_hash = filebase64sha256(var.lambda_etl_file_path)
  timeout          = 10
  layers           = [aws_lambda_layer_version.python_layer.arn]

  environment {
    variables = var.s3
  }
}

resource "aws_lambda_permission" "allow_s3_to_invoke_lambda" {
  statement_id  = "AllowS3InvokeLambda"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_etl_function_name
  principal     = "s3.amazonaws.com"
  source_arn    = var.bucket_arn
}

resource "aws_lambda_layer_version" "python_layer" {
  layer_name          = "python_layer"
  filename            = var.python_layer
  compatible_runtimes = ["python3.9"]
}

resource "aws_cloudwatch_log_group" "lambda_etl_logs" {
  name              = "/aws/lambda/${aws_lambda_function.lambda_etl_function.function_name}"
  retention_in_days = 7
}

### Cron job not required at this moment. ###
### Requests using selenium in lambda results in too much overhead. ###
# resource "aws_cloudwatch_event_rule" "etl_lambda_schedule" {
#   name                = "requests_lambda_schedule"
#   schedule_expression = "cron(0/30 * * * ? *)" # Every 30 minutes
# }
