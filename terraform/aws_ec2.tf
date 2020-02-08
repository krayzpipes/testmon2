resource "aws_lb_target_group" "testmon" {
  name        = "tf-testmon-dev-lb-tg"
  port        = 8080
  protocol    = "TCP"
  target_type = "ip"
  vpc_id      = module.testmon_vpc.vpc_id
  stickiness {
    type = "lb_cookie"
    enabled = false
  }
  health_check {
    port = "traffic-port"
    protocol = "TCP"
  }
}

resource "aws_lb" "testmon" {
  name               = "testmon-lb-tf"
  internal           = false
  load_balancer_type = "network"
  subnets            = module.testmon_vpc.public_subnets
  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_listener" "testmon_web" {
  load_balancer_arn = aws_lb.testmon.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.testmon.arn
  }
}