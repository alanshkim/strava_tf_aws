resource "aws_s3_bucket" "strava_run_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_policy" "strava_bucket_policy" {
  bucket = aws_s3_bucket.strava_run_bucket.id
  policy = data.aws_iam_policy_document.strava_bucket_access.json
}

data "aws_iam_policy_document" "strava_bucket_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["211125379323"]
    }

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:ListBucket"
    ]

    resources = [
      aws_s3_bucket.strava_run_bucket.arn,
      "${aws_s3_bucket.strava_run_bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_notification" "s3_bucket_notifications" {
  bucket = aws_s3_bucket.strava_run_bucket.id

  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "raw/"
    filter_suffix       = ".json" # Specify file type if needed
  }
}

resource "aws_s3_object" "glue_script" {
  bucket = aws_s3_bucket.strava_run_bucket.id
  key    = "glue_job.py"
  source = "../scripts/glue_job.py"
}

resource "aws_s3_object" "config_setting" {
  bucket = aws_s3_bucket.strava_run_bucket.id
  key    = "config/config.zip"
  source = "../data/config.zip"
}

### No longer in use. Json files directly uploaded to S3 bucket in the python script.###
# resource "aws_s3_object" "athlete_json" {
#   bucket = aws_s3_bucket.strava_run_bucket.id
#   key    = "athlete.json"
#   source = "../data/raw/athlete.json"
# }

# resource "aws_s3_object" "stats_json" {
#   bucket = aws_s3_bucket.strava_run_bucket.id
#   key    = "stats.json"
#   source = "../data/raw/stats.json"
# }

# resource "aws_s3_object" "activities_json" {
#   bucket = aws_s3_bucket.strava_run_bucket.id
#   key    = "activities.json"
#   source = "../data/raw/activities.json"
# }

# resource "aws_s3_object" "comments_json" {
#   bucket = aws_s3_bucket.strava_run_bucket.id
#   key    = "comments.json"
#   source = "../data/raw/comments.json"
# }