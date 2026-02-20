variable "region" {
  description = "AWS Region"
  type        = string
}

variable "ip_range" {
  description = "IP range to use for AWSMGN Source Instances/Servers"
  type        = string
}

variable "instance_type_windows_iis" {
  description = "The Amazon EC2 instance type for the Application Tier"
  type        = string
}

variable "instance_type_windows_sql" {
  description = "The Amazon EC2 instance type for the Database Tier"
  type        = string
}

variable "my_public_ip" {
  description = "Your public IP address for security group rules"
  type        = string
}

variable "name_suffix" {
  description = "Suffix to append to resource names for uniqueness"
  type        = string
}

variable "create_instances" {
  description = "Whether to create EC2 instances in this region"
  type        = bool
  default     = true
}

variable "region_map" {
  description = "Map of AMIs per region"
  type        = map(map(string))
  default = {
    "us-east-1" = {
      "AmiWindowsIIS" = "ami-03c312f0b0f394f16"
      "AmiWindowsSQL" = "ami-078f1c68e538dfead"
    }
    "us-east-2" = {
      "AmiWindowsIIS" = "ami-08c0f5771f45074c3"
      "AmiWindowsSQL" = "ami-00304e0ec6d2d2cb8"
    }
  }
}
