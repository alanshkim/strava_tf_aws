output "bucket_arn" {
  value = aws_s3_bucket.strava_run_bucket.arn
}

output "bucket_name" {
  value = aws_s3_bucket.strava_run_bucket.bucket
}
