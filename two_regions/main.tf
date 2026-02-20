

# ------------------------------------------------------------------------
# Variables (Parameters)
# ------------------------------------------------------------------------

variable "ip_range" {
  description = "IP range to use for AWSMGN Source Instances/Servers"
  type        = string
  default     = "172.31.0.0/20"

  validation {
    condition     = can(cidrhost(var.ip_range, 0))
    error_message = "Must be a valid CIDR block."
  }
}

variable "instance_type_windows_iis" {
  description = "The Amazon EC2 instance type for the Application Tier running PHP on Windows Server IIS."
  type        = string
  default     = "t3a.large"
}

variable "instance_type_windows_sql" {
  description = "The Amazon EC2 instance type for the Database Tier running SQL Server on Windows Server."
  type        = string
  default     = "t3a.large"
}

# ------------------------------------------------------------------------
# Data Source: Get My Public IP (shared across regions)
# ------------------------------------------------------------------------
data "http" "myip" {
  url = "https://checkip.amazonaws.com"
}

# ------------------------------------------------------------------------
# Deploy to us-east-1 (NO INSTANCES)
# ------------------------------------------------------------------------

module "us_east_1" {
  source = "./modules/mgn-infrastructure"

  providers = {
    aws = aws.us_east_1
  }

  region                    = "us-east-1"
  ip_range                  = var.ip_range
  instance_type_windows_iis = var.instance_type_windows_iis
  instance_type_windows_sql = var.instance_type_windows_sql
  my_public_ip              = chomp(data.http.myip.response_body)
  name_suffix               = "use1"
  create_instances          = false  # No instances in us-east-1
}

# ------------------------------------------------------------------------
# Deploy to us-east-2 (WITH INSTANCES)
# ------------------------------------------------------------------------

module "us_east_2" {
  source = "./modules/mgn-infrastructure"

  providers = {
    aws = aws.us_east_2
  }

  region                    = "us-east-2"
  ip_range                  = var.ip_range
  instance_type_windows_iis = var.instance_type_windows_iis
  instance_type_windows_sql = var.instance_type_windows_sql
  my_public_ip              = chomp(data.http.myip.response_body)
  name_suffix               = "use2"
  create_instances          = true  # Create instances in us-east-2
}
