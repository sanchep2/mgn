# ------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------

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
    Name = "AWSMGNSource-VPC-${var.name_suffix}"
  }
}

resource "aws_subnet" "source" {
  vpc_id            = aws_vpc.source.id
  cidr_block        = var.ip_range
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "AWSMGNSource-Subnet-${var.name_suffix}"
  }
}

resource "aws_internet_gateway" "source" {
  vpc_id = aws_vpc.source.id

  tags = {
    Name = "AWSMGNSource-IGW-${var.name_suffix}"
  }
}

resource "aws_route_table" "source" {
  vpc_id = aws_vpc.source.id

  tags = {
    Name = "AWSMGNSource-RouteTable-${var.name_suffix}"
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
  name        = "AWSMGN-Instances-${var.name_suffix}"
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
    Name = "AWSMGN-SecurityGroup-${var.name_suffix}"
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
# Security Group Rules (Ingress)
# ------------------------------------------------------------------------

# Allow HTTP (Port 80)
resource "aws_security_group_rule" "ingress_http_myip" {
  type              = "ingress"
  description       = "Allow HTTP from my Public IP"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.source.id
  cidr_blocks       = ["${var.my_public_ip}/32"]
}

# Allow RDP (Port 3389)
resource "aws_security_group_rule" "ingress_rdp_myip" {
  type              = "ingress"
  description       = "Allow RDP from my Public IP"
  from_port         = 3389
  to_port           = 3389
  protocol          = "tcp"
  security_group_id = aws_security_group.source.id
  cidr_blocks       = ["${var.my_public_ip}/32"]
}

# ------------------------------------------------------------------------
# IAM Role for SSM (only created when instances are created)
# ------------------------------------------------------------------------

resource "aws_iam_role" "ssm_role" {
  count = var.create_instances ? 1 : 0

  name = "AWSMGN-SSM-Role-${var.name_suffix}"

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
    Name = "AWSMGN-SSM-Role-${var.name_suffix}"
  }
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  count = var.create_instances ? 1 : 0

  role       = aws_iam_role.ssm_role[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm_profile" {
  count = var.create_instances ? 1 : 0

  name = "AWSMGN-SSM-InstanceProfile-${var.name_suffix}"
  role = aws_iam_role.ssm_role[0].name
}

# ------------------------------------------------------------------------
# Launch Template & Instances (only created when create_instances = true)
# ------------------------------------------------------------------------

resource "aws_launch_template" "mgn" {
  count = var.create_instances ? 1 : 0

  name = "MGNInstanceTemplate-${var.name_suffix}"

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "optional"
    instance_metadata_tags = "enabled"
  }
}

resource "aws_instance" "iis" {
  count = var.create_instances ? 1 : 0

  ami           = var.region_map[var.region]["AmiWindowsIIS"]
  instance_type = var.instance_type_windows_iis

  iam_instance_profile = aws_iam_instance_profile.ssm_profile[0].name

  launch_template {
    id      = aws_launch_template.mgn[0].id
    version = "$Latest"
  }

  # Network Interface settings
  subnet_id                   = aws_subnet.source.id
  vpc_security_group_ids      = [aws_security_group.source.id]
  associate_public_ip_address = true

  tags = {
    Name = "AWSMGN-Windows-IIS-${var.name_suffix}"
  }
}

resource "aws_instance" "sql" {
  count = var.create_instances ? 1 : 0

  ami           = var.region_map[var.region]["AmiWindowsSQL"]
  instance_type = var.instance_type_windows_sql

  iam_instance_profile = aws_iam_instance_profile.ssm_profile[0].name

  launch_template {
    id      = aws_launch_template.mgn[0].id
    version = "$Latest"
  }

  # Network Interface settings (Fixed IP as per CFN)
  subnet_id                   = aws_subnet.source.id
  vpc_security_group_ids      = [aws_security_group.source.id]
  associate_public_ip_address = true
  private_ip                  = "172.31.12.40"

  tags = {
    Name = "AWSMGN-Windows-SQL-${var.name_suffix}"
  }
}

# ------------------------------------------------------------------------
# SSM Association (only created when instances are created)
# ------------------------------------------------------------------------

resource "aws_ssm_association" "update_agent" {
  count = var.create_instances ? 1 : 0

  name = "AWS-UpdateSSMAgent"

  schedule_expression = "rate(14 days)"
  max_errors          = "1"
  max_concurrency     = "1"

  targets {
    key    = "InstanceIds"
    values = [aws_instance.iis[0].id, aws_instance.sql[0].id]
  }
}
