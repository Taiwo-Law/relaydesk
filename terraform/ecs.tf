resource "aws_ecs_cluster" "main" {
  name = "${lower(var.project_name)}-cluster"

  tags = {
    Name = "${var.project_name}-cluster"
  }
}

data "aws_iam_policy_document" "ecs_task_execution_assume_role" {
  statement {
    effect = "Allow"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "Service"

      identifiers = [
        "ecs-tasks.amazonaws.com"
      ]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution" {
  name               = "${lower(var.project_name)}-ecs-task-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_execution_assume_role.json

  tags = {
    Name = "${var.project_name}-ecs-task-execution-role"
  }
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Security exception: RelayDesk currently pulls images from public GHCR
# and requires outbound internet access. Egress is restricted to HTTPS only.
#trivy:ignore:AWS-0104
resource "aws_security_group" "ecs_tasks" {
  name        = "${lower(var.project_name)}-ecs-tasks-sg"
  description = "Security group for RelayDesk ECS tasks"
  vpc_id      = aws_vpc.main.id

  egress {
    description = "Allow outbound HTTPS for image pulls and AWS service communication"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ecs-tasks-sg"
  }
}