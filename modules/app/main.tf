locals {
  queue_name = "${var.app_name}-${var.environment}-queue"
}

resource "aws_sqs_queue" "main" {
  name                       = local.queue_name
  visibility_timeout_seconds = 99

  tags = {
    Name = local.queue_name
  }
}
