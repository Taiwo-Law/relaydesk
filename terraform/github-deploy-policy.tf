data "aws_iam_policy_document" "github_actions_deploy" {
  statement {
    effect = "Allow"

    actions = [
      "ecs:UpdateService",
      "ecs:DescribeServices"
    ]

    resources = [
      aws_ecs_service.relaydesk.id
    ]
  }
}

resource "aws_iam_role_policy" "github_actions_deploy" {
  name   = "${lower(var.project_name)}-github-actions-deploy"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_actions_deploy.json
}