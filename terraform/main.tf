resource "aws_iam_role" "strava_role" {
  name = "strava_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = [
            "lambda.amazonaws.com",
            "glue.amazonaws.com",
            "states.amazonaws.com",
            "s3.amazonaws.com",
            "events.amazonaws.com"
          ]
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "all_in_one_policy" {
  name        = "AllInOnePolicy"
  description = "Comprehensive policy for Lambda, Glue, and Step Functions actions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "lambda:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "glue:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "states:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "s3:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "events:*"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_all_in_one_policy" {
  role       = aws_iam_role.strava_role.name
  policy_arn = aws_iam_policy.all_in_one_policy.arn
}

module "s3_bucket" {
  source              = "./modules/s3"
  bucket_name         = var.bucket_name
  lambda_function_arn = module.lambda_function.lambda_function_arn
}

module "lambda_function" {
  source                   = "./modules/lambda"
  lambda_access_role_arn   = aws_iam_role.strava_role.arn
  lambda_etl_function_name = "strava_etl_lambda_function"
  lambda_etl_file_path     = "../data/etl.zip"
  lambda_runtime           = "python3.9"
  lambda_handler           = "scripts.etl.lambda_handler"
  python_layer             = "../lambda_layers/python_layer.zip"
  bucket_name              = var.bucket_name
  bucket_arn               = module.s3_bucket.bucket_arn
  object_keys              = var.object_keys
  aws_region               = var.aws_region
  s3                       = var.s3
}

module "glue" {
  source               = "./modules/glue"
  glue_job_name        = "pyspark_glue_job"
  script_location      = "glue_job.py"
  config_location      = "config/config.zip"
  temp_dir             = "s3://your-bucket/temp/"
  json_file            = "processed/activities.json" 
  glue_access_role_arn = aws_iam_role.strava_role.arn
  bucket_name          = var.bucket_name

}