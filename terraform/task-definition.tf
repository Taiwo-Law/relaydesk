resource "aws_ecs_task_definition" "relaydesk" {
  family                   = "${lower(var.project_name)}-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name      = "relaydesk"
      image     = "ghcr.io/taiwo-law/relaydesk:latest"
      essential = true

      portMappings = [
        {
          containerPort = 5000
          protocol      = "tcp"
        }
      ]
    }
  ])

  tags = {
    Name = "${var.project_name}-task"
  }
}