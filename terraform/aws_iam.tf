data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecsTestmonTaskExecutionRolePolicy"
  role = aws_iam_role.ecs_task_execution_role.id
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTestmonTaskExecutionRole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_user" "circle_ci" {
  name = "circle_ci"
  path = "/"

  tags = {
    user_type = "functional"
  }
}

resource "aws_iam_access_key" "circle_ci" {
  user = aws_iam_user.circle_ci.name
}

resource "aws_iam_group" "ecr_automation" {
  name = "ecr_automation"
  path = "/"
}

resource "aws_iam_group_membership" "ecr_automation" {
  name = "ecr_automation_group_membership"
  group = aws_iam_group.ecr_automation.name

  users = [
    aws_iam_user.circle_ci.name
  ]
}

resource "aws_iam_group_policy" "testmon_ecr_automation_policy" {
  name = "testmon_ecr_automation_group_policy"
  group = aws_iam_group.ecr_automation.id

  policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "TestmonManageRepository",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability",
                "ecr:PutImage",
                "ecr:InitiateLayerUpload",
                "ecr:UploadLayerPart",
                "ecr:CompleteLayerUpload",
                "ecr:DescribeRepositories",
                "ecr:GetRepositoryPolicy",
                "ecr:ListImages",
                "ecr:DeleteRepository",
                "ecr:BatchDeleteImage",
                "ecr:SetRepositoryPolicy",
                "ecr:DeleteRepositoryPolicy",
                "ecs:DeregisterTaskDefinition",
                "ecs:DescribeServices",
                "ecs:DescribeTaskDefinition",
                "ecs:DescribeTasks",
                "ecs:ListTasks",
                "ecs:ListTaskDefinitions",
                "ecs:RegisterTaskDefinition",
                "ecs:StartTask",
                "ecs:StopTask",
                "ecs:UpdateService",
                "iam:PassRole"
            ],
            "Resource": [
             "*"
            ]
        }
    ]
}
EOF
}


