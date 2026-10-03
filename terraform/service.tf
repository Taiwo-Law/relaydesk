resource "aws_vpc_security_group_ingress_rule" "relaydesk" {
  security_group_id = aws_security_group.ecs_tasks.id

  description = "Allow HTTP traffic to RelayDesk"
  from_port   = 5000
  to_port     = 5000
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"
}

resource "aws_ecs_service" "relaydesk" {
  name            = "${lower(var.project_name)}-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.relaydesk.arn
  desired_count   = var.ecs_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  tags = {
    Name = "${var.project_name}-service"
  }
}