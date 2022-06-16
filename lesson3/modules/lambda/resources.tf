# data "aws_caller_identity" "current" {}

# data "aws_iam_policy_document" "lambda_source_code_bucket_policy" {
#   statement {
#     principals {
#       type        = "AWS"
#       identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"]
#     }
#     actions = ["s3:*"]
#     effect  = "Deny"

#     resources = [
#       "arn:aws:s3:::${var.lambda_source_code_bucket_name}",
#       "arn:aws:s3:::${var.lambda_source_code_bucket_name}/*"
#     ]
#     condition {
#       test     = "Bool"
#       variable = "aws:SecureTransport"
#       values   = ["false"]
#     }
#   }
# }

# module "lambda_source_code_bucket" {
#   source                  = "terraform-aws-modules/s3-bucket/aws"
#   version                 = "3.2.0"
#   bucket                  = var.lambda_source_code_bucket_name
#   acl                     = "private"
#   block_public_acls       = true
#   block_public_policy     = true
#   ignore_public_acls      = true
#   restrict_public_buckets = true
#   versioning = {
#     status = true
#   }

#   attach_policy = true
#   policy        = data.aws_iam_policy_document.lambda_source_code_bucket_policy.json

#   server_side_encryption_configuration = {
#     rule = {
#       apply_server_side_encryption_by_default = {
#         sse_algorithm = "aws:kms"
#       }
#     }
#   }
# }

resource "aws_iam_role" "tf_workshop_role" {
  name = "${var.lambda_name}_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "tf_workshop_policy" {
  name        = "${var.lambda_name}_policy"
  path        = "/"
  description = "${var.lambda_name} policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      #   {
      #     Action = "s3:*",
      #     Effect = "Allow",
      #     Resource = [
      #       "arn:aws:s3:::${var.lambda_source_code_bucket_name}",
      #       "arn:aws:s3:::${var.lambda_source_code_bucket_name}/*",
      #     ]
      #   },
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = "arn:aws:logs:*:*:*",
        Effect   = "Allow"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "tf_workshop_policy_attachment" {
  name       = "${var.lambda_name}_policy_attachment"
  roles      = [aws_iam_role.tf_workshop_role.name]
  policy_arn = aws_iam_policy.tf_workshop_policy.arn
}

resource "aws_cloudwatch_log_group" "tf_workshop_log_group" {
  name              = "/aws/lambda/${var.lambda_name}"
  retention_in_days = 90
}

data "archive_file" "init" {
  type        = "zip"
  output_path = "${path.module}/lambda.zip"
  source {
    content  = file("${path.module}/source_code.js")
    filename = "source_code.js"
  }
}

resource "aws_lambda_function" "tf_workshop" {
  function_name    = var.lambda_name
  filename         = data.archive_file.init.output_path
  source_code_hash = data.archive_file.init.output_base64sha256
  role             = aws_iam_role.tf_workshop_role.arn
  handler          = "source_code.handler"
  runtime          = "nodejs16.x"

  tags = {
    Name = var.lambda_name
  }
}