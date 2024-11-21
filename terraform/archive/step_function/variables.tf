variable "state_machine_name" {
  description = "The name of the Step Function state machine"
  type        = string
}

variable "lambda_function_arn" {
  description = "The ARN of the Lambda function to run first in the Step Function"
  type        = string
}

variable "glue_job_name" {
  description = "The name of the Glue job to trigger after Lambda"
  type        = string
}

variable "region" {
  description = "AWS region for the Glue job ARN"
  type        = string
}
