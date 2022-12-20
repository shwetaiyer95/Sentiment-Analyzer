terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = "us-east-1"
  access_key = var.ACCESS_KEY
  secret_key = var.SECRET_KEY
  token      = var.TOKEN
}

resource "aws_security_group" "sec-grp" {
  name        = "ec2-sec-grp"
  description = "Allow HTTP and SSH traffic via Terraform"

  ingress {
    description = "http rule"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }

  ingress {
    description = "ssh rule"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "application port"
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "smart-feed-sec-grp"
  }
}

resource "aws_security_group" "rds-sec-grp" {
  name        = "rds-sec-grp"
  description = "Allow public connectivity for RDS via Terraform"

  ingress {
    description = "rds connectivity"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "smart-feed-rds-sec-grp"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage   = 20
  identifier          = "smart-feed-db"
  storage_type        = "gp2"
  engine              = "mysql"
  engine_version      = "8.0.28"
  instance_class      = "db.t2.medium"
  snapshot_identifier = "arn:aws:rds:us-east-1:138734174841:snapshot:termproject-team1-db-snapshot"
  db_name             = var.DB_NAME
  username            = var.DB_USERNAME
  password            = var.DB_PASSWORD
  publicly_accessible = true
  skip_final_snapshot = true
  depends_on                  = [aws_security_group.rds-sec-grp]
  vpc_security_group_ids      = [aws_security_group.rds-sec-grp.id]

  tags = {
    Name = "smart-feed-mysql-db"
  }
}

output "db_host_and_port" {
  value = aws_db_instance.rds_instance.endpoint
}

resource "aws_sqs_queue" "sqs-queue" {
  name                       = "apigateway-queue"
  delay_seconds              = 0
  visibility_timeout_seconds = 1800
  max_message_size           = 262144
  message_retention_seconds  = 86400
  receive_wait_time_seconds  = 10
}

resource "aws_api_gateway_rest_api" "apigatewaytosqs" {
  name        = "apiendpoint"
  description = "API Endpoint for triggering SQS"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "send-message" {
  rest_api_id = aws_api_gateway_rest_api.apigatewaytosqs.id
  parent_id   = aws_api_gateway_rest_api.apigatewaytosqs.root_resource_id
  path_part   = "send_message"
}

resource "aws_api_gateway_method" "send-message-POST" {
  rest_api_id   = aws_api_gateway_rest_api.apigatewaytosqs.id
  resource_id   = aws_api_gateway_resource.send-message.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "api-integration" {
  rest_api_id             = aws_api_gateway_rest_api.apigatewaytosqs.id
  resource_id             = aws_api_gateway_resource.send-message.id
  http_method             = aws_api_gateway_method.send-message-POST.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  credentials             = var.IAM_ROLE_ARN
  uri                     = "arn:aws:apigateway:us-east-1:sqs:path/${aws_sqs_queue.sqs-queue.name}"

  request_parameters = {
    "integration.request.header.Content-Type" = "'application/x-www-form-urlencoded'"
  }

  passthrough_behavior = "NEVER"

  request_templates = {
    "application/json" = "Action=SendMessage&MessageBody=$input.body"
  }
}

resource "aws_api_gateway_method_response" "api-method-response" {
  rest_api_id = aws_api_gateway_rest_api.apigatewaytosqs.id
  resource_id = aws_api_gateway_resource.send-message.id
  http_method = aws_api_gateway_method.send-message-POST.http_method
  status_code = "200"

  depends_on = [
    aws_api_gateway_method.send-message-POST
  ]
}

resource "aws_api_gateway_integration_response" "api-integration-response" {
  rest_api_id = aws_api_gateway_rest_api.apigatewaytosqs.id
  resource_id = aws_api_gateway_resource.send-message.id
  http_method = aws_api_gateway_method.send-message-POST.http_method
  status_code = aws_api_gateway_method_response.api-method-response.status_code

  depends_on = [
    aws_api_gateway_integration.api-integration
  ]
}


resource "aws_api_gateway_deployment" "smartfeed-api-gateway-deployment" {
  rest_api_id = aws_api_gateway_rest_api.apigatewaytosqs.id

  depends_on = [
    aws_api_gateway_rest_api.apigatewaytosqs,
    aws_api_gateway_integration_response.api-integration-response,
    aws_api_gateway_method_response.api-method-response
  ]
}

resource "aws_api_gateway_stage" "smartfeed-api-endpoint" {
  deployment_id = aws_api_gateway_deployment.smartfeed-api-gateway-deployment.id
  rest_api_id   = aws_api_gateway_rest_api.apigatewaytosqs.id
  stage_name    = "dev"

  depends_on = [
    aws_api_gateway_deployment.smartfeed-api-gateway-deployment
  ]
}

output "api_gateway_url" {
  description = "Base URL for API Gateway."
  value       = join("", [aws_api_gateway_deployment.smartfeed-api-gateway-deployment.invoke_url, "dev/send_message"])
}

data "archive_file" "lambda_with_dependencies" {
  source_file = "lambdacode.py"
  output_path = "lambdacode.zip"
  type        = "zip"
}

resource "aws_lambda_layer_version" "lambda_layer" {
  filename   = "python.zip"
  layer_name = "lambda_layer"
}

resource "aws_lambda_function" "smartfeed_lambda_function" {
  filename      = "lambdacode.zip"
  function_name = "sqs_lambda_function"
  layers        = [aws_lambda_layer_version.lambda_layer.arn]
  role          = var.IAM_ROLE_ARN
  handler       = "lambdacode.lambda_handler"
  runtime       = "python3.8"
  timeout       = 899

  environment {
    variables = {
      DB_ENDPOINT   = split(":", aws_db_instance.rds_instance.endpoint)[0],
      DB_PORT       = split(":", aws_db_instance.rds_instance.endpoint)[1],
      DB_USER       = var.DB_USERNAME,
      DB_NAME       = var.DB_NAME,
      DB_PASS       = var.DB_PASSWORD,
      TWITTER_TOKEN = var.TWITTER_TOKEN,
      TOKEN         = var.TOKEN,
      ACCESS_KEY    = var.ACCESS_KEY,
      SECRET_KEY    = var.SECRET_KEY
      LAMBDA_KEY    = var.LAMBDA_KEY
    }
  }
}

# Adding sqs trigger for lambda
resource "aws_lambda_event_source_mapping" "event_source_mapping" {
  event_source_arn = aws_sqs_queue.sqs-queue.arn
  enabled          = true
  function_name    = aws_lambda_function.smartfeed_lambda_function.arn
  batch_size       = 1
}

resource "aws_cloudwatch_event_rule" "smartfeed-cw-event" {
  name                = "smartfeed-scheduled-refresh-event"
  description         = "cloudwatch event to refresh tweets"
  schedule_expression = "rate(5 minutes)"
  role_arn            = var.IAM_ROLE_ARN
}

resource "aws_cloudwatch_event_target" "profile_generator_lambda_target" {
  arn   = aws_lambda_function.smartfeed_lambda_function.arn
  rule  = aws_cloudwatch_event_rule.smartfeed-cw-event.name
  input = <<JSON
{
  "refresh": "true",
  "api_key": "${var.LAMBDA_KEY}"
}
JSON
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_rw_fallout_retry_step_deletion_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.smartfeed_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.smartfeed-cw-event.arn
}

resource "aws_instance" "server" {
  ami                         = "ami-02da6ad9b37942098"
  instance_type               = "t2.medium"
  associate_public_ip_address = true
  depends_on                  = [aws_security_group.sec-grp]
  vpc_security_group_ids      = [aws_security_group.sec-grp.id]
  key_name                    = var.EC2_KEY

  user_data = <<-EOF
    #!/bin/bash
    sudo su

    echo "DB_USER=${var.DB_USERNAME}" >> /etc/environment
    echo "USER_KEY=${var.DB_PASSWORD}" >> /etc/environment
    echo "HOST=${split(":", aws_db_instance.rds_instance.endpoint)[0]}" >> /etc/environment
    echo "DB_PORT=${split(":", aws_db_instance.rds_instance.endpoint)[1]}" >> /etc/environment
    echo "API_URL=${join("", [aws_api_gateway_deployment.smartfeed-api-gateway-deployment.invoke_url,"dev/send_message"])}" >> /etc/environment
    echo "API_KEY=${var.LAMBDA_KEY}" >> /etc/environment
    echo "DB_NAME=${var.DB_NAME}" >> /etc/environment

    EOF

  tags = {
    Name = "smart-feed-server"
  }
}

output "steps_to_host_website" {
  value = join("\n", [
    "Please run these commands.", "1. Use CloudShell to SSH into EC2 using:",
    join("", ["ssh -i \"", var.EC2_KEY, ".pem\" ec2-user@", join(",", aws_instance.server.*.public_dns)]),
    "2.Run env command to check if EC2 is initialized completely. All user data should be there.",
    "3.Change directory by running:", "cd smart_feed/",
    "4.Run application by executing this python command:", "python3 manage.py runserver 0:8000",
    "5.Access the website using the link:", join("", ["http://", join(",", aws_instance.server.*.public_ip), ":8000/"])
  ])
}