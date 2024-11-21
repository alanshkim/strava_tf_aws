variable "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  type        = string
}

variable "glue_job_name" {
  description = "The ARN of the glue name"
  type        = string
}

variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "eventbridge_access_role_arn" {
  description = "The ARN for eventbridge access"
  type        = string
}
