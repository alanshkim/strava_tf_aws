output "state_machine_arn" {
  description = "The ARN of the Step Function state machine"
  value       = aws_sfn_state_machine.lambda_glue_workflow.arn
}
