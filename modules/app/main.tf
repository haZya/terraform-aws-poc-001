locals {
  queue_name = "${var.app_name}-${var.environment}-queue"
}

resource "aws_sqs_queue" "main" {
  name = local.queue_name

  tags = {
    Name = local.queue_name
  }
}
