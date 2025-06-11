# Hands-On: Lambda Goes A.I.

resource "aws_s3_bucket" "doc_ai_bucket" {
  bucket_prefix = "doc-ai"
  force_destroy = true
}

resource "aws_s3_bucket_notification" "doc_upload_trigger" {
  bucket = aws_s3_bucket.doc_ai_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.doc_ai_lambda.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "input/documents/"
  }

  depends_on = [aws_lambda_permission.allow_s3_to_invoke]
}

resource "aws_iam_role" "lambda_role" {
  name = "doc-ai-lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Effect = "Allow",
      Sid    = ""
    }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_policy" "doc_ai_policy" {
  name = "DocAIFullPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "textract:*",
          "translate:*",
          "comprehend:*",
          "s3:GetObject",
          "s3:PutObject"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_doc_ai_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.doc_ai_policy.arn
}

resource "aws_lambda_function" "doc_ai_lambda" {
  function_name = "doc-ai-lambda"
  runtime       = "python3.11"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"

  filename = "lambda_function_payload.zip"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
}

resource "aws_lambda_permission" "allow_s3_to_invoke" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.doc_ai_lambda.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.doc_ai_bucket.arn
}