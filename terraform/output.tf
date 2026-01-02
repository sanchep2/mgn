# ------------------------------------------------------------------------
# Network Outputs
# ------------------------------------------------------------------------

output "vpc_id" {
  description = "The ID of the Source VPC"
  value       = aws_vpc.source.id
}

output "subnet_id" {
  description = "The ID of the Source Subnet"
  value       = aws_subnet.source.id
}

# ------------------------------------------------------------------------
# Instance Outputs
# ------------------------------------------------------------------------

output "iis_instance_id" {
  description = "Instance ID for the Windows IIS Server"
  value       = aws_instance.iis.id
}

output "iis_public_ip" {
  description = "Public IP address for the Windows IIS Server"
  value       = aws_instance.iis.public_ip
}

output "iis_private_ip" {
  description = "Private IP address for the Windows IIS Server"
  value       = aws_instance.iis.private_ip
}

output "sql_instance_id" {
  description = "Instance ID for the Windows SQL Server"
  value       = aws_instance.sql.id
}

output "sql_public_ip" {
  description = "Public IP address for the Windows SQL Server"
  value       = aws_instance.sql.public_ip
}

output "sql_private_ip" {
  description = "Private IP address for the Windows SQL Server"
  value       = aws_instance.sql.private_ip
}