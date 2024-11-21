resource "aws_glue_job" "pyspark_job" {
  name     = var.glue_job_name
  role_arn = var.glue_access_role_arn
  command {
    name            = "glueetl"
    script_location = "s3://${var.bucket_name}/${var.script_location}" # S3 path to your glue script
    python_version  = "3"
  }

  default_arguments = {
    "--job-bookmark-option" = "job-bookmark-enable"
    "--TempDir"             = var.temp_dir # Temporary S3 path for Glue job
    "--file-name"           = var.json_file
    "--extra-py-files"      = "s3://${var.bucket_name}/${var.config_location}"
  }

  max_retries = 1
}