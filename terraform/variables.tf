variable "aws_region" {
  description = "AWS region used for RelayDesk infrastructure"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Name used to identify RelayDesk AWS resources"
  type        = string
  default     = "RelayDesk"
}

variable "vpc_cidr" {
  description = "CIDR block for the RelayDesk VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for the public subnets"
  type        = list(string)

  default = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]
}

variable "ecs_desired_count" {
  description = "Number of RelayDesk Fargate tasks to run"
  type        = number
  default     = 0
}