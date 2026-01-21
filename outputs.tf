output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "List of IDs of public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "List of IDs of private subnets"
  value       = aws_subnet.private[*].id
}

output "alb_dns_name" {
  description = "The DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "db_master_endpoint" {
  description = "The endpoint of the master database"
  value       = aws_db_instance.master.endpoint
}

output "db_replica_endpoint" {
  description = "The endpoint of the replica database"
  value       = aws_db_instance.replica.endpoint
}
