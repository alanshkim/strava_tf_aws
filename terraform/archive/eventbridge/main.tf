# EventBridge Rule to Monitor Lambda Success
resource "aws_cloudwatch_event_rule" "lambda_success_rule" {
  name        = "LambdaSuccessToTriggerGlue"
  description = "Triggers Glue job when Lambda completes successfully"
  event_pattern = jsonencode({
    "source" : ["aws.lambda"],
    "detail-type" : ["AWS API Call via CloudTrail"],
    "detail" : {
      "eventName" : ["Invoke"],
      "responseElements" : {
        "statusCode" : [200]
      },
      "requestParameters" : {
        "functionName" : [var.lambda_function_arn]
      }
    }
  })
  depends_on = [var.lambda_function_arn]
}

data "aws_caller_identity" "current" {}

# Target Glue Job for EventBridge Rule
resource "aws_cloudwatch_event_target" "glue_job_target" {
  rule     = aws_cloudwatch_event_rule.lambda_success_rule.name
  arn      = "arn:aws:glue:${var.aws_region}:${data.aws_caller_identity.current.account_id}:job/${var.glue_job_name}"
  role_arn = var.eventbridge_access_role_arn
}

# Permission for EventBridge to trigger Glue
resource "aws_lambda_permission" "allow_eventbridge_to_invoke_glue" {
  statement_id  = "AllowEventBridgeInvokeGlue"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_arn
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.lambda_success_rule.arn
}
