# ------------------------------------------------------------------------
# Outputs for us-east-1 (Infrastructure only, no instances)
# ------------------------------------------------------------------------

output "us_east_1_vpc_id" {
  description = "VPC ID in us-east-1"
  value       = module.us_east_1.vpc_id
}

output "us_east_1_subnet_id" {
  description = "Subnet ID in us-east-1"
  value       = module.us_east_1.subnet_id
}

output "us_east_1_security_group_id" {
  description = "Security Group ID in us-east-1"
  value       = module.us_east_1.security_group_id
}

# ------------------------------------------------------------------------
# Outputs for us-east-2 (Infrastructure + Instances)
# ------------------------------------------------------------------------

output "us_east_2_vpc_id" {
  description = "VPC ID in us-east-2"
  value       = module.us_east_2.vpc_id
}

output "us_east_2_subnet_id" {
  description = "Subnet ID in us-east-2"
  value       = module.us_east_2.subnet_id
}

output "us_east_2_security_group_id" {
  description = "Security Group ID in us-east-2"
  value       = module.us_east_2.security_group_id
}

output "us_east_2_iis_instance_id" {
  description = "IIS Instance ID in us-east-2"
  value       = module.us_east_2.iis_instance_id
}

output "us_east_2_iis_public_ip" {
  description = "IIS Instance Public IP in us-east-2"
  value       = module.us_east_2.iis_public_ip
}

output "us_east_2_sql_instance_id" {
  description = "SQL Instance ID in us-east-2"
  value       = module.us_east_2.sql_instance_id
}

output "us_east_2_sql_public_ip" {
  description = "SQL Instance Public IP in us-east-2"
  value       = module.us_east_2.sql_public_ip
}
