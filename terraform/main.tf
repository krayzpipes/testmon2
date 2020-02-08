provider "aws" {
  version = "~> 2.0"
  region  = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

output "ecs_cluster_arn" {
  value = aws_ecs_cluster.testmon.arn
}

output "ecs_security_group_id" {
  value = module.testmon_ecs_sg.this_security_group_id
}

output "ecs_security_group_subnet_ids" {
  value = module.testmon_vpc.private_subnets
}

output "ecr_image_repo_url" {
  value = aws_ecr_repository.testmon_repo.repository_url
}

output "target_group_arn" {
  value = aws_lb_target_group.testmon.arn
}

output "task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

