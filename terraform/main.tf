
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
# Mappings (Replicated from CloudFormation)
# ------------------------------------------------------------------------

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

# ------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------

data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}

# ------------------------------------------------------------------------
# Networking Resources
# ------------------------------------------------------------------------

resource "aws_vpc" "source" {
  cidr_block           = var.ip_range
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "AWSMGNSource-VPC"
  }
}

resource "aws_subnet" "source" {
  vpc_id            = aws_vpc.source.id
  cidr_block        = var.ip_range
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "AWSMGNSource-Subnet"
  }
}

resource "aws_internet_gateway" "source" {
  vpc_id = aws_vpc.source.id

  tags = {
    Name = "AWSMGNSource-IGW"
  }
}

resource "aws_route_table" "source" {
  vpc_id = aws_vpc.source.id

  tags = {
    Name = "AWSMGNSource-RouteTable"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = aws_route_table.source.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.source.id
}

resource "aws_route_table_association" "source" {
  subnet_id      = aws_subnet.source.id
  route_table_id = aws_route_table.source.id
}

# ------------------------------------------------------------------------
# Security Groups
# ------------------------------------------------------------------------

resource "aws_security_group" "source" {
  name        = "AWSMGN-Instances"
  description = "Security Group (firewall) protecting source machines for AWSMGN"
  vpc_id      = aws_vpc.source.id

  # Egress All
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "AWSMGN-SecurityGroup"
  }
}

# Self-referencing Ingress Rule
resource "aws_security_group_rule" "ingress_self" {
  type                     = "ingress"
  description              = "All Intra-VPC traffic allowed"
  from_port                = 0
  to_port                  = 0
  protocol                 = "-1"
  security_group_id        = aws_security_group.source.id
  source_security_group_id = aws_security_group.source.id
}

# ------------------------------------------------------------------------
# IAM Role for SSM
# ------------------------------------------------------------------------

resource "aws_iam_role" "ssm_role" {
  name = "AWSMGN-SSM-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "AWSMGN-SSM-Role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  name = "AWSMGN-SSM-InstanceProfile"
  role = aws_iam_role.ssm_role.name
}

# ------------------------------------------------------------------------
# Launch Template & Instances
# ------------------------------------------------------------------------

resource "aws_launch_template" "mgn" {
  name = "MGNInstanceTemplate"

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    instance_metadata_tags      = "enabled"
  }
}

resource "aws_instance" "iis" {
  ami           = var.region_map[data.aws_region.current.name]["AmiWindowsIIS"]
  instance_type = var.instance_type_windows_iis
  
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  launch_template {
    id      = aws_launch_template.mgn.id
    version = "$Latest"
  }

  # Network Interface settings
  subnet_id                   = aws_subnet.source.id
  vpc_security_group_ids      = [aws_security_group.source.id]
  associate_public_ip_address = true

  tags = {
    Name = "AWSMGN-Windows-IIS"
  }
}

resource "aws_instance" "sql" {
  ami           = var.region_map[data.aws_region.current.name]["AmiWindowsSQL"]
  instance_type = var.instance_type_windows_sql
  
  iam_instance_profile = aws_iam_instance_profile.ssm_profile.name

  launch_template {
    id      = aws_launch_template.mgn.id
    version = "$Latest"
  }

  # Network Interface settings (Fixed IP as per CFN)
  subnet_id                   = aws_subnet.source.id
  vpc_security_group_ids      = [aws_security_group.source.id]
  associate_public_ip_address = true
  private_ip                  = "172.31.12.40"

  tags = {
    Name = "AWSMGN-Windows-SQL"
  }
}

# ------------------------------------------------------------------------
# SSM Association
# ------------------------------------------------------------------------

resource "aws_ssm_association" "update_agent" {
  name = "AWS-UpdateSSMAgent"

  schedule_expression = "rate(14 days)"
  max_errors          = "1"
  max_concurrency     = "1"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.iis.id, aws_instance.aws_instance.sql.id]
  }
}