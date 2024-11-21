variable "glue_job_name" {
  description = "The name of the Glue job"
  type        = string
}

variable "script_location" {
  description = "The S3 path to the Glue script"
  type        = string
}

variable "config_location" {
  description = "The config path for config module import for glue script"
  type        = string
}
variable "temp_dir" {
  description = "The S3 path for temporary files"
  type        = string
}

variable "json_file" {
  description = "The file for the glue job"
  type = string
}
variable "glue_access_role_arn" {
  description = "The ARN for eventbridge access"
  type        = string
}

variable "bucket_name" {
  type = string
}