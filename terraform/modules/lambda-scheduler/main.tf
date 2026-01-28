# Lambda Scheduler Module - Auto scale down/up for cost savings

data "aws_caller_identity" "current" {}

# IAM Role for Lambda
resource "aws_iam_role" "scheduler" {
  name = "${var.project_name}-${var.environment}-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "scheduler" {
  name = "scheduler-permissions"
  role = aws_iam_role.scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "rds:StopDBInstance",
          "rds:StartDBInstance",
          "rds:DescribeDBInstances"
        ]
        Resource = "arn:aws:rds:${var.aws_region}:${data.aws_caller_identity.current.account_id}:db:${var.rds_instance_id}"
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Lambda function code
data "archive_file" "scheduler" {
  type        = "zip"
  output_path = "${path.module}/scheduler.zip"

  source {
    content  = <<-EOF
import boto3
import os
import json

def handler(event, context):
    action = event.get('action', 'scale_down')
    ecs_cluster = os.environ['ECS_CLUSTER']
    ecs_service = os.environ['ECS_SERVICE']
    rds_instance = os.environ['RDS_INSTANCE']

    ecs = boto3.client('ecs')
    rds = boto3.client('rds')

    results = {'ecs': None, 'rds': None}

    if action == 'scale_up':
        # Scale up ECS
        ecs.update_service(
            cluster=ecs_cluster,
            service=ecs_service,
            desiredCount=1
        )
        results['ecs'] = 'Scaled up to 1 task'

        # Start RDS
        try:
            rds.start_db_instance(DBInstanceIdentifier=rds_instance)
            results['rds'] = 'Starting RDS instance'
        except rds.exceptions.InvalidDBInstanceStateFault:
            results['rds'] = 'RDS already running'

    elif action == 'scale_down':
        # Scale down ECS
        ecs.update_service(
            cluster=ecs_cluster,
            service=ecs_service,
            desiredCount=0
        )
        results['ecs'] = 'Scaled down to 0 tasks'

        # Stop RDS
        try:
            rds.stop_db_instance(DBInstanceIdentifier=rds_instance)
            results['rds'] = 'Stopping RDS instance'
        except rds.exceptions.InvalidDBInstanceStateFault:
            results['rds'] = 'RDS already stopped'

    print(json.dumps(results))
    return results
EOF
    filename = "lambda_function.py"
  }
}

# Lambda Function
resource "aws_lambda_function" "scheduler" {
  filename         = data.archive_file.scheduler.output_path
  function_name    = "${var.project_name}-${var.environment}-scheduler"
  role             = aws_iam_role.scheduler.arn
  handler          = "lambda_function.handler"
  source_code_hash = data.archive_file.scheduler.output_base64sha256
  runtime          = "python3.12"
  timeout          = 60

  environment {
    variables = {
      ECS_CLUSTER  = var.ecs_cluster_arn
      ECS_SERVICE  = var.ecs_service_name
      RDS_INSTANCE = var.rds_instance_id
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-scheduler"
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "scheduler" {
  name              = "/aws/lambda/${aws_lambda_function.scheduler.function_name}"
  retention_in_days = 7

  tags = var.tags
}

# EventBridge Rule - Scale Up
resource "aws_cloudwatch_event_rule" "scale_up" {
  name                = "${var.project_name}-${var.environment}-scale-up"
  description         = "Scale up ECS and RDS"
  schedule_expression = var.scale_up_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "scale_up" {
  rule      = aws_cloudwatch_event_rule.scale_up.name
  target_id = "scale-up-lambda"
  arn       = aws_lambda_function.scheduler.arn

  input = jsonencode({
    action = "scale_up"
  })
}

resource "aws_lambda_permission" "scale_up" {
  statement_id  = "AllowScaleUpEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scale_up.arn
}

# EventBridge Rule - Scale Down
resource "aws_cloudwatch_event_rule" "scale_down" {
  name                = "${var.project_name}-${var.environment}-scale-down"
  description         = "Scale down ECS and RDS"
  schedule_expression = var.scale_down_schedule

  tags = var.tags
}

resource "aws_cloudwatch_event_target" "scale_down" {
  rule      = aws_cloudwatch_event_rule.scale_down.name
  target_id = "scale-down-lambda"
  arn       = aws_lambda_function.scheduler.arn

  input = jsonencode({
    action = "scale_down"
  })
}

resource "aws_lambda_permission" "scale_down" {
  statement_id  = "AllowScaleDownEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduler.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.scale_down.arn
}
