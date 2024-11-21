variable "lambda_access_role_arn" {
  description = "The ARN for eventbridge access"
  type        = string
}

variable "lambda_etl_function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "lambda_etl_file_path" {
  description = "Path to the zip file containing the Lambda function code"
  type        = string
}

variable "lambda_runtime" {
  description = "Runtime for the Lambda function (e.g., python3.9)"
  type        = string
}

variable "lambda_handler" {
  description = "Handler for the Lambda function (e.g., lambda_function.lambda_handler)"
  type        = string
}

variable "python_layer" {
  description = "Lambda layer for python dependecies"
  type        = string
}
variable "bucket_name" {
  description = "Bucket name"
  type        = string
}

variable "bucket_arn" {
  type        = string
  description = "ARN of the S3 bucket allowed to invoke Lambda"
}

variable "object_keys" {
  description = "List of object keys"
  type        = string
}

variable "aws_region" {
  description = "The AWS region for Lambda resources"
  type        = string
}

variable "s3" {
  description = "s3 bucket details"
  type        = map(string)
}

### Request credentials not required at this time. ###
### Requests using selenium in lambda results in too much overhead. ###
# variable "request_credentials" {
#   description = "Credentials for the request_data lambda function"
#   type        = map(string)
# }

