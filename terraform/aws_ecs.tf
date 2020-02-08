
resource "aws_ecs_cluster" "testmon" {
  name = "testmon"
  capacity_providers = ["FARGATE"]
}
