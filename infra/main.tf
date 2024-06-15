### S3 Bucket Settings ###

resource "aws_s3_bucket" "movies_bucket_tf" {

  bucket = "movies-bucket-tf"
  tags = {
    Name        = "movies-bucket-tf"
    Environment = "dev"
  }
}

resource "aws_s3_bucket_public_access_block" "bucket_public_access" {
  bucket = aws_s3_bucket.movies_bucket_tf.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_objects_public_access" {
  bucket = aws_s3_bucket.movies_bucket_tf.id
  policy = data.aws_iam_policy_document.allow_objects_public_access.json
}

data "aws_iam_policy_document" "allow_objects_public_access" {
  statement {
    actions = [
      "s3:*"
    ]

    resources = [
        aws_s3_bucket.movies_bucket_tf.arn,
      "${aws_s3_bucket.movies_bucket_tf.arn}/*"
    ]

    principals {
      type        = "AWS"
      identifiers = ["284807706316"]
    }
  }

  statement {
    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.movies_bucket_tf.arn}/*"
    ]

    principals {
      type        = "*"
      identifiers = ["*"]
    }
  }
}

resource "aws_s3_object" "oppenheimer_object" {
  bucket = aws_s3_bucket.movies_bucket_tf.id
  key    = "oppenheimer.jpg"
  source = "${path.module}/oppenheimer.jpg"
}

resource "aws_s3_object" "darkknight_object" {
  bucket = aws_s3_bucket.movies_bucket_tf.id
  key    = "thedarkknight.jpg"
  source = "${path.module}/thedarkknight.jpg"
}

resource "aws_s3_object" "wallstreet_object" {
  bucket = aws_s3_bucket.movies_bucket_tf.id
  key    = "wolfofwallstreet.jpg"
  source = "${path.module}/wolfofwallstreet.jpg"
}

### DynamoDB Table Settings ###

resource "aws_dynamodb_table" "movies_table" {
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "title"
  name         = "movies_tf"
  
  attribute {
    name = "title"
    type = "S"
  }

  attribute {
    name = "releaseYear"
    type = "S"
  }

  global_secondary_index {
    name               = "ReleaseYearIndex"
    hash_key           = "releaseYear"
    projection_type    = "ALL"
  }
}

resource "aws_dynamodb_table_item" "movies_item1" {
  table_name = aws_dynamodb_table.movies_table.name
  hash_key   = aws_dynamodb_table.movies_table.hash_key

  item = <<ITEM
{
  "title": {"S": "Oppenheimer"},
  "releaseYear": {"S": "2023"},
  "genre": {"S": "Drama, History"},
  "coverUrl": {"S": "https://movies-bucket-tf.s3.ap-southeast-1.amazonaws.com/oppenheimer.jpg"}
}
ITEM
}

resource "aws_dynamodb_table_item" "movies_item2" {
  table_name = aws_dynamodb_table.movies_table.name
  hash_key   = aws_dynamodb_table.movies_table.hash_key

  item = <<ITEM

{
  "title": {"S": "The Dark Knight"},
  "releaseYear": {"S": "2008"},
  "genre": {"S": "Action, Crime, Drama"},
  "coverUrl": {"S": "https://movies-bucket-tf.s3.ap-southeast-1.amazonaws.com/thedarkknight.jpg"}
}
ITEM
}

resource "aws_dynamodb_table_item" "movies_item3" {
  table_name = aws_dynamodb_table.movies_table.name
  hash_key   = aws_dynamodb_table.movies_table.hash_key

  item = <<ITEM

{
  "title": {"S": "The Wolf of Wall Street"},
  "releaseYear": {"S": "2013"},
  "genre": {"S": "Biography, Crime, Drama"},
  "coverUrl": {"S": "https://movies-bucket-tf.s3.ap-southeast-1.amazonaws.com/wolfofwallstreet.jpg"}
}
ITEM
}

### Lambda Function Settings ###

resource "aws_lambda_function" "movies_lambda" {
  filename         = data.archive_file.zip_the_python_code.output_path
  function_name    = "movies_lambda"
  role             = aws_iam_role.movies_lambda_role.arn
  handler          = "movies_lambda.lambda_handler"
  source_code_hash = data.archive_file.zip_the_python_code.output_base64sha256
  runtime = "python3.9"
}

resource "aws_lambda_function" "movieyear_lambda" {
  filename         = data.archive_file.zip_the_python_code_2.output_path
  function_name    = "movieyear_lambda"
  role             = aws_iam_role.movies_lambda_role.arn
  handler          = "movieyear_lambda.lambda_handler"
  source_code_hash = data.archive_file.zip_the_python_code_2.output_base64sha256
  runtime = "python3.9"
}

resource "aws_iam_role" "movies_lambda_role" {
  name = "movies_lambda_role"

  assume_role_policy = jsonencode({
  Version = "2012-10-17"
  Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

}

resource "aws_iam_policy" "iam_policy_for_movies_lambda" {

  name        = "aws_iam_policy_for_movies_lambda_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing various movies lambda role"
  policy = jsonencode(
    {
      Version : "2012-10-17",
      Statement : [
        {
          Action : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource : "arn:aws:logs:*:*:*",
          Effect : "Allow"
        },
        {
          Effect : "Allow"
          Action : [
            "dynamodb:Scan",
            "dynamodb:Query"
            
          ]
          Resource = [aws_dynamodb_table.movies_table.arn, "${aws_dynamodb_table.movies_table.arn}/index/ReleaseYearIndex"]
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role       = aws_iam_role.movies_lambda_role.name
    policy_arn = aws_iam_policy.iam_policy_for_movies_lambda.arn
}

data "archive_file" "zip_the_python_code" {
  type        = "zip"
  source_file = "${path.module}/lambda/movies_lambda.py"
  output_path = "${path.module}/lambda/movies_lambda.zip"
}

data "archive_file" "zip_the_python_code_2" {
  type        = "zip"
  source_file = "${path.module}/lambda/movieyear_lambda.py"
  output_path = "${path.module}/lambda/movieyear_lambda.zip"
}

resource "aws_lambda_function_url" "movies_lambda_url" {
  function_name      = aws_lambda_function.movies_lambda.function_name
  authorization_type = "NONE"
}

resource "aws_lambda_function_url" "movieyear_lambda_url" {
  function_name      = aws_lambda_function.movieyear_lambda.function_name
  authorization_type = "NONE"
}