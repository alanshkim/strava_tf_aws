output "lambda_function_arn" {
  value = aws_lambda_function.lambda_etl_function.arn
}

output "lambda_function_name" {
  value = aws_lambda_function.lambda_etl_function.function_name
}

### Request credentials not required at this time. ###
### Requests using selenium in lambda results in too much overhead. ###
# output "lambda_requests_function_arn" {
#   value = aws_lambda_function.request_api_data.arn
# }