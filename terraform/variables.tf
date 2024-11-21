variable "aws_region" {
  default = "us-east-1"
  type    = string
}

variable "bucket_name" {
  default = "strava-run-bucket"
  type    = string
}

variable "object_keys" {
  default = "athlete.json, stats.json, activities.json, comments.json"
  type    = string
}

variable "s3" {
  description = "s3 bucket details"
  type        = map(string)
}

### Request credentials not required at this time. ###
### Requests using selenium in lambda results in too much overhead. ###
# variable "request_credentials" {
#   type = object({
#     STRAVA_USERNAME = string
#     STRAVA_PASSWORD = string
#     ATHLETE_ID      = number
#     CLIENT_ID       = number
#     CLIENT_SECRET   = string
#     REDIRECT_URL    = string
#     SCOPE           = string
#   })
#   description = "Credentials for the request_data lambda function"
# }

