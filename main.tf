provider "aws"{

   # aws_profile and aws_region should be defined in '.config' and '.credential' file while setting up the CLI environment 
   # and their values are passed via command line

    profile = var.profile
    region = var.region

}

# Getting the appropriate AWS Availability Zone
data "aws_availability_zones" "availablilityZones" {}

# Creating a VPC with a VPC Name
resource "aws_vpc" "vpc"{

    cidr_block = var.vpcCIDRblock
    

    enable_dns_support = var.dnsSupport
    enable_dns_hostnames = var.dnsHostNames
    enable_classiclink_dns_support = true
    assign_generated_ipv6_cidr_block = false

    tags = {
        Name = "${var.vpcName}_${timestamp()}"
    }
}

# Creating subnets with appropraite subnet names and subnet-cidr-block
resource "aws_subnet" "subnet"{

    count = length(var.subnetCIDRblock)

    cidr_block = var.subnetCIDRblock[count.index]

    vpc_id = aws_vpc.vpc.id
    availability_zone = data.aws_availability_zones.availablilityZones.names[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "${var.vpcName}_Subnet${count.index}_${timestamp()}"
    }
}

# Creating an Internet Gateway
resource "aws_internet_gateway" "igw" {

    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "${var.vpcName}_InternetGateway"
    }
}

# Creating the Route Table
resource "aws_default_route_table" "route_table" {

    default_route_table_id = aws_vpc.vpc.default_route_table_id

    tags = {
        Name = "${var.vpcName}_RouteTable_${timestamp()}"
    }
}

# Create the Internet Access
resource "aws_route" "vpc_internet_access" {

  route_table_id = aws_default_route_table.route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id = aws_internet_gateway.igw.id

}

# Associating Route Table with the Subnets
resource "aws_route_table_association" "subnetAssociation" {

    count = length(var.subnetCIDRblock)
    subnet_id = element(aws_subnet.subnet.*.id, count.index)
    route_table_id = aws_default_route_table.route_table.id

}

# Application Security Group
resource "aws_security_group" "application_security_group" {
  name         = "application_security_group"
  vpc_id       = aws_vpc.vpc.id
  
  # allow ingress of port 22
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  } 

   # allow ingress of port 80
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  } 

  # allow ingress of port 80
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
  } 

   # allow ingress of port 3000
  ingress {
    cidr_blocks = var.ingressCIDRblock  
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
  } 
  
  # allow egress of all ports
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = var.egressCIDRblock
  }

    tags = {
        Name = "Application_Security_Group"
        Description = "Application Security Group"
    }
}

# Database Security Group
resource "aws_security_group" "database_security_group" {

  name         = "database_security_group"
  vpc_id       = aws_vpc.vpc.id

  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [ aws_security_group.application_security_group.id ]
  } 

  tags = {
        Name = "Database_Security_Group"
        Description = "Database Security Group"
  }
}

# S3 Bucket 
resource "aws_s3_bucket" "s3_bucket" {

  bucket = var.S3BucketName
  acl = "private"
  force_destroy = "true"

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm     = "aws:kms"
      }
    }
  }

  lifecycle_rule {
    enabled = true

    transition {
      days = 30
      storage_class = "STANDARD_IA"
    }
  }

  tags = {
        Name = var.S3BucketName
        Description = "S3 Bucket"
  }

   depends_on = [aws_subnet.subnet]

}
resource "aws_s3_bucket_public_access_block" "s3Private" {
  bucket = aws_s3_bucket.s3_bucket.id
  ignore_public_acls = true
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}

# RDS DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "rds-subnet-group"
  subnet_ids = aws_subnet.subnet.*.id

  tags = {
    Name = "RDS Subnet group"
  }
}

# RDS DB Instance
resource "aws_db_instance" "rds" {

    allocated_storage = 20
    storage_type = "gp2"
    engine = "mysql"
    engine_version = "5.7"
    instance_class = "db.t3.micro"
    publicly_accessible = false
    multi_az = false
    identifier = var.rdsInstanceIdentifier
    name = var.rdsDBName
    username = var.rdsUsername
    password = var.rdsPassword
    skip_final_snapshot = true

    vpc_security_group_ids = [ aws_security_group.database_security_group.id ]
    db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.id

}

#Dynamo DB Table
resource "aws_dynamodb_table" "dynamodb_table" {
    name  = var.dynamoDBName
    read_capacity  = 20
    write_capacity = 20
    hash_key = "id"

    attribute {
      name = "id"
      type = "S"
    }

    tags = {
      Name = var.dynamoDBName
    }
}


# IAM Policies

# IAM Policy for S3 Bucket 
resource "aws_iam_policy" "S3_Policy" {
  name = "WebAppS3_Policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetObject",
                "s3:DeleteObject"
            ],
            "Resource": "arn:aws:s3:::webapp.deep.gamit/*"
        }
    ]
}
EOF
}

# IAM Roles

# IAM Role for EC2 Instance
resource "aws_iam_role" "EC2_Role" {
  name = "EC2-CSYE6225"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "EC2-CSYE6225"
  }
}

# IAM Roles and Policies Attachments

# EC2 Role and S3 Policy Attachment
resource "aws_iam_role_policy_attachment" "EC2Role_S3Policy" {
  role       = aws_iam_role.EC2_Role.name
  policy_arn = aws_iam_policy.S3_Policy.arn

}

// Fetch latest published AMI
data "aws_ami" "application_ami" {
  owners = [var.accountId]
  most_recent = true

  filter {
    name   = "name"
    values = ["csye6225_*"]
  }
}

# Profile for the EC2 Instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "ec2_profile"
  role =  aws_iam_role.EC2_Role.name
}

# EC2 Instance
resource "aws_instance" "ec2_instance" {

   ami = data.aws_ami.application_ami.id
   instance_type = "t2.micro"
   vpc_security_group_ids = [ aws_security_group.application_security_group.id ]
   disable_api_termination = false
   key_name = var.aws_ssh_key
   subnet_id = aws_subnet.subnet[0].id
   associate_public_ip_address = true
   iam_instance_profile = aws_iam_instance_profile.ec2_profile.name
   user_data = templatefile("${path.module}/aws_instance_userdata.sh",
                  {
                    aws_db_host = aws_db_instance.rds.address,
                    aws_app_port = var.application_port,
                    s3_bucket_name = aws_s3_bucket.s3_bucket.id,
                    aws_db_name = aws_db_instance.rds.name,
                    aws_db_username = aws_db_instance.rds.username,
                    aws_db_password = aws_db_instance.rds.password,
                    aws_region = var.region
                  })

   root_block_device {
     volume_type = "gp2"
     volume_size = "20"
     delete_on_termination = true
   }

   tags = {

     Name = "EC2Instance-CSYE6225"
   }

  depends_on = [aws_s3_bucket.s3_bucket,aws_db_instance.rds]
   
 }