provider "aws" {
  region = "us-east-1"
}

resource "aws_iam_role" "example_role" {
  name = "example_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "states.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_stepfunctions_state_machine" "step_function1" {
  name     = "step_function1"
  definition = <<DEFINITION
{
  "Comment": "Step Function that does nothing",
  "StartAt": "Task1",
  "States": {
    "Task1": {
      "Type": "Pass",
      "End": true
    }
  }
}
DEFINITION

  role_arn = aws_iam_role.example_role.arn
}

resource "aws_lambda_function" "lambda1" {
  function_name = "lambda1"
  filename      = "lambda1.zip"
  role          = aws_iam_role.example_role.arn
  handler       = "index.handler"
  runtime       = "python3.8"
  environment = {
    variables = {
      "example_variable" = "example_value"
    }
  }
}

resource "aws_iam_role_policy" "example_policy" {
  name = "example_policy"
  role = aws_iam_role.example_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
          "states:StartExecution"
        ],
        Resource = [
          "arn:aws:lambda:us-west-2:${var.aws_account_id}:function:lambda1",
          "arn:aws:states:us-west-2:${var.aws_account_id}:stateMachine:step_function1"
        ],
        Effect = "Allow",
        Condition = {
          "ArnLike": {
            "aws:SourceArn": [
              "arn:aws:lambda:us-west-2:${var.aws_account_id}:function:lambda1"
            ]
          },
          "StringEquals": {
            "aws:SourceAccount": [
              "${var.aws_account_id}"
            ]
          }
        }
      }
    ]
  })
}