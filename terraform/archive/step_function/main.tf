resource "aws_sfn_state_machine" "lambda_glue_workflow" {
  name     = var.state_machine_name
  role_arn = aws_iam_role.step_functions_role.arn
  definition = jsonencode({
    Comment = "A workflow that runs Lambda followed by Glue",
    StartAt = "InvokeLambda",
    States = {
      InvokeLambda = {
        Type     = "Task",
        Resource = "arn:aws:states:::lambda:invoke",
        Parameters = {
          FunctionName = var.lambda_function_arn
        },
        Next = "StartGlueJob",
        Catch = [
          {
            ErrorEquals = ["States.ALL"],
            Next        = "FailState"
          }
        ]
      },
      StartGlueJob = {
        Type     = "Task",
        Resource = "arn:aws:states:::glue:startJobRun.sync",
        Parameters = {
          JobName = var.glue_job_name
        },
        End = true
      },
      FailState = {
        Type  = "Fail",
        Error = "JobFailed",
        Cause = "The initial Lambda function failed."
      }
    }
  })
}

# IAM role for Step Function to allow access to Lambda and Glue
resource "aws_iam_role" "step_functions_role" {
  name = "${var.state_machine_name}_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "step_functions_policy" {
  name        = "${var.state_machine_name}_policy"
  description = "Step Functions permissions for Lambda and Glue"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "lambda:InvokeFunction",
          "glue:StartJobRun",
          "states:*",
          "s3:*"
        ],
        Resource = [
          var.lambda_function_arn,
          "arn:aws:glue:${var.region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_job_name}"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "step_functions_role_policy_attach" {
  role       = aws_iam_role.step_functions_role.name
  policy_arn = aws_iam_policy.step_functions_policy.arn
}


