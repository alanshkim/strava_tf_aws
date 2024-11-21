variable "bucket_name" {
  type = string
}

variable "lambda_function_arn" {
  description = "ARN of the Lambda function to be triggered"
  type        = string
}
