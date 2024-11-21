output "glue_job_name" {
  value = aws_glue_job.pyspark_job.name
}

output "glue_job_arn" {
  value = aws_glue_job.pyspark_job.arn
}