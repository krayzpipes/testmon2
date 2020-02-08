
# Account/Region
variable "aws_region" {
  default = "us-east-1"
}
variable "aws_access_key" {}
variable "aws_secret_key" {}

# Route53
variable "aws_local_zone" {
  default = "testmon.local"
}
variable "aws_redis_record_name" {
  default = "redis.testmon.local"
}

# CIDRS allowed to access application
variable "aws_whitelist_cidrs" {}

# Container info
variable "container_name" {}
variable "container_tag" {}