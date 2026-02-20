output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.source.id
}

output "subnet_id" {
  description = "Subnet ID"
  value       = aws_subnet.source.id
}

output "security_group_id" {
  description = "Security Group ID"
  value       = aws_security_group.source.id
}

output "iis_instance_id" {
  description = "IIS Instance ID"
  value       = var.create_instances ? aws_instance.iis[0].id : null
}

output "iis_public_ip" {
  description = "IIS Instance Public IP"
  value       = var.create_instances ? aws_instance.iis[0].public_ip : null
}

output "sql_instance_id" {
  description = "SQL Instance ID"
  value       = var.create_instances ? aws_instance.sql[0].id : null
}

output "sql_public_ip" {
  description = "SQL Instance Public IP"
  value       = var.create_instances ? aws_instance.sql[0].public_ip : null
}
