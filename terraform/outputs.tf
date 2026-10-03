output "vpc_id" {
  description = "ID of the RelayDesk VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "IDs of the RelayDesk public subnets"
  value       = aws_subnet.public[*].id
}

output "internet_gateway_id" {
  description = "ID of the RelayDesk Internet Gateway"
  value       = aws_internet_gateway.main.id
}