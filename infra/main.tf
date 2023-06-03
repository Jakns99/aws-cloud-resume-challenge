data "archive_file" "lambda_zip" {
  type        = "zip"
  source      = "${path.module}/lambda/"
  output_path = "${path.module}/packedlambda.zip"
}

resource "aws_dynamodb_table" "DynamoDBTable" {
  name           = "cloud-resume-challenge-counter"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "ID"
  read_capacity  = 20
  write_capacity = 20

  attribute {
    name = "ID"
    type = "S"
  }
}

resource "aws_lambda_function_url" "url" {
  function_name      = aws_lambda_function.myfunc.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["date", "keep-alive"]
    expose_headers    = ["keep-alive", "date"]
    max_age           = 86400
  }
}


resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "cloud_resume_policy" {

  name        = "aws_iam_policy_for_terraform_resume_project_policy"
  path        = "/"
  description = "AWS IAM Policy for managing the resume project role"
    policy = jsonencode(
    {
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Action" : [
            "logs:CreateLogGroup",
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ],
          "Resource" : "arn:aws:logs:*:*:*",
          "Effect" : "Allow"
        },
        {
          "Effect" : "Allow",
          "Action" : [
            "dynamodb:UpdateItem",
			      "dynamodb:GetItem"
          ],
          "Resource" : "arn:aws:dynamodb:*:*:table/cloud-resume-challenge-counter"
        },
      ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
  role = aws_iam_role.iam_for_lambda.name
  policy_arn = aws_iam_policy.cloud_resume_policy.arn 
}


resource "aws_lambda_function" "lambda_function" {
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  function_name    = "function"
  role             = aws_iam_role.lambda_role.arn
  handler          = "func.handler"
  runtime          = "python3.10"

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.DynamoDBTable.name
    }
  }

  tracing_config {
    mode = "Active"
  }
}
resource "aws_api_gateway_rest_api" "MyApi" {
  name        = "cloud-resume-challenge"
  description = "API Gateway for Cloud Resume Challenge"
}

resource "aws_api_gateway_resource" "ApiResource" {
  rest_api_id = aws_api_gateway_rest_api.MyApi.id
  parent_id   = aws_api_gateway_rest_api.MyApi.root_resource_id
  path_part   = "get"
}

resource "aws_api_gateway_method" "ApiMethod" {
  rest_api_id   = aws_api_gateway_rest_api.MyApi.id
  resource_id   = aws_api_gateway_resource.ApiResource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "ApiIntegration" {
  rest_api_id = aws_api_gateway_rest_api.MyApi.id
  resource_id = aws_api_gateway_resource.ApiResource.id
  http_method = aws_api_gateway_method.ApiMethod.http_method

  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.lambda_function.invoke_arn
}

resource "aws_api_gateway_deployment" "MyDeployment" {
  depends_on = [aws_api_gateway_integration.ApiIntegration]
  
  rest_api_id = aws_api_gateway_rest_api.MyApi.id
  stage_name  = "Prod"
}