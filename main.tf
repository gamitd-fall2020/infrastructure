provider "aws"{

   # aws_profile and aws_region should be defined in '.config' and '.credential' file while setting up the CLI environment 
   # and their values are passed via command line

    profile = var.profile
    region = var.region

}

# Getting the appropriate AWS Availability Zone
data "aws_availability_zones" "availablilityZones" {}

# Getting the Account ID of AWS Account
data "aws_caller_identity" "env" {}

locals {
  aws_account_id = data.aws_caller_identity.env.account_id
}

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

# Dynamo DB Table
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

# IAM Roles

# IAM Role for CodeDeploy
resource "aws_iam_role" "codeDeploy_role" {
  name = "CodeDeployServiceRole"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "codedeploy.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

# IAM Role for CodeDeploy EC2
resource "aws_iam_role" "codeDeploy_EC2_role" {
  name = "CodeDeployEC2ServiceRole"

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
}

# CodeDeploy Application 
resource "aws_codedeploy_app" "codeDeploy_application" {
  compute_platform = "Server"
  name             = "csye6225-webapp"
}

# CodeDeploy Deployment Group 
resource "aws_codedeploy_deployment_group" "codeDeploy_deploymentGroup" {
  app_name              = aws_codedeploy_app.codeDeploy_application.name
  deployment_group_name = "csye6225-webapp-deployment"
  deployment_config_name = "CodeDeployDefault.AllAtOnce"
  service_role_arn      = aws_iam_role.codeDeploy_role.arn

  ec2_tag_filter {
    key   = "Name"
    type  = "KEY_AND_VALUE"
    value = "EC2Instance-CSYE6225"
  }

  deployment_style {
    deployment_option = "WITHOUT_TRAFFIC_CONTROL"
    deployment_type   = "IN_PLACE"
  }

  auto_rollback_configuration {
    enabled = true
    events  = ["DEPLOYMENT_FAILURE"]
  }

  depends_on = [aws_codedeploy_app.codeDeploy_application]
}


# IAM Policies

# IAM Policy for ghactions User
resource "aws_iam_policy" "GH-E2-Instance" {
  name = "GH-E2-Instance"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AttachVolume",
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:CopyImage",
                "ec2:CreateImage",
                "ec2:CreateKeypair",
                "ec2:CreateSecurityGroup",
                "ec2:CreateSnapshot",
                "ec2:CreateTags",
                "ec2:CreateVolume",
                "ec2:DeleteKeyPair",
                "ec2:DeleteSecurityGroup",
                "ec2:DeleteSnapshot",
                "ec2:DeleteVolume",
                "ec2:DeregisterImage",
                "ec2:DescribeImageAttribute",
                "ec2:DescribeImages",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "ec2:DescribeRegions",
                "ec2:DescribeSecurityGroups",
                "ec2:DescribeSnapshots",
                "ec2:DescribeSubnets",
                "ec2:DescribeTags",
                "ec2:DescribeVolumes",
                "ec2:DetachVolume",
                "ec2:GetPasswordData",
                "ec2:ModifyImageAttribute",
                "ec2:ModifyInstanceAttribute",
                "ec2:ModifySnapshotAttribute",
                "ec2:RegisterImage",
                "ec2:RunInstances",
                "ec2:StopInstances",
                "ec2:TerminateInstances"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}
resource "aws_iam_policy" "GH-Upload-To-S3" {
  name = "GH-Upload-To-S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:Get*",
        "s3:List*"
        ],
      "Resource":[ 
        "arn:aws:s3:::codedeploy.${var.profile}.${var.domainName}/*",
        "arn:aws:s3:::codedeploy.${var.profile}.${var.domainName}"
      ]
    }
  ]
}
EOF
}
resource "aws_iam_policy" "GH-Code-Deploy" {
  name = "GH-Code-Deploy"
  policy = <<EOF
{
  "Version" : "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:RegisterApplicationRevision",
        "codedeploy:GetApplicationRevision"
      ],
      "Resource": "arn:aws:codedeploy:${var.region}:${local.aws_account_id}:application:${aws_codedeploy_app.codeDeploy_application.name}"
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:CreateDeployment",
        "codedeploy:GetDeployment"
      ],
      "Resource": "arn:aws:codedeploy:${var.region}:${local.aws_account_id}:deploymentgroup:${aws_codedeploy_app.codeDeploy_application.name}/${aws_codedeploy_deployment_group.codeDeploy_deploymentGroup.deployment_group_name}"
      
    },
    {
      "Effect": "Allow",
      "Action": [
        "codedeploy:GetDeploymentConfig"
      ],
      "Resource": [
        "arn:aws:codedeploy:${var.region}:${local.aws_account_id}:deploymentconfig:CodeDeployDefault.OneAtATime",
        "arn:aws:codedeploy:${var.region}:${local.aws_account_id}:deploymentconfig:CodeDeployDefault.HalfAtATime",
        "arn:aws:codedeploy:${var.region}:${local.aws_account_id}:deploymentconfig:CodeDeployDefault.AllAtOnce"
      ]
    }
  ]
}
EOF
}

# IAM Policy for CodeDeploy Role
# This policy allows EC2 Instance to read & upload data from S3 bucket.
resource "aws_iam_policy" "CodeDeploy-EC2-S3" {
  name = "CodeDeploy-EC2-S3"
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:Get*",
        "s3:List*",
        "s3:PutObject",
        "s3:DeleteObject",
        "s3:DeleteObjectVersion"
      ],
      "Effect": "Allow",
      "Resource": [
        "arn:aws:s3:::codedeploy.${var.profile}.${var.domainName}/*",
        "arn:aws:s3:::${var.S3BucketName}/*"
      ]
    }
  ]
}
EOF
}

# IAM User and Policies Attaachment

# ghactions User and EC2 Instance Policy Attachment

resource "aws_iam_user_policy_attachment" "ghactions_EC2_policy_attach" {
  user = "ghactions"
  policy_arn = aws_iam_policy.GH-E2-Instance.arn
}

# ghactions User and S3 Policy Attachment

resource "aws_iam_user_policy_attachment" "ghactions_S3_policy_attach" {
  user = "ghactions"
  policy_arn = aws_iam_policy.GH-Upload-To-S3.arn
}

# ghactions User and CodeDeploy Policy Attachment

resource "aws_iam_user_policy_attachment" "ghactions_codeDeploy_policy_attach" {
  user = "ghactions"
  policy_arn = aws_iam_policy.GH-Code-Deploy.arn
}

# IAM Roles and Policies Attachments

# CodeDeploy Role and CodeDeploy Policy Attachment
resource "aws_iam_role_policy_attachment" "CodeDeployRole_CodeDeployPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
  role       = aws_iam_role.codeDeploy_role.name
}

# CodeDeploy Role and EC2 Instances Policy Attachment
resource "aws_iam_role_policy_attachment" "CodeDeployRole_EC2Policy" {
  policy_arn = aws_iam_policy.CodeDeploy-EC2-S3.arn
  role       = aws_iam_role.codeDeploy_EC2_role.name
}

# EC2 Instance and CloudWatch Agent Policy Attachment
resource "aws_iam_role_policy_attachment" "CloudWatchAgent_EC2Policy" {
  role = aws_iam_role.codeDeploy_EC2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
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
  role =  aws_iam_role.codeDeploy_EC2_role.name
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

 # Route 53 Zone Data
data "aws_route53_zone" "selected" {
  name         = "${var.profile}.${var.domainName}"
  private_zone = false
}

 # Add/Update DNS record to public IP of EC2 Instance
 resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "api.${var.profile}.${var.domainName}"
  type    = "A"
  ttl     = "60"
  records = [aws_instance.ec2_instance.public_ip]
  depends_on = [aws_instance.ec2_instance]
}