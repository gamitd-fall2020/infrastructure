provider "aws"{
  
    region = var.region

}

# Create VPC
resource "aws_vpc" "vpc"{

    cidr_block = var.vpcCIDRblock

    enable_dns_support = var.dnsSupport
    enable_dns_hostnames = var.dnsHostNames
    enable_classiclink_dns_support = true
    assign_generated_ipv6_cidr_block = false

    tags = {
        Name = "My_VPC"
    }
}

# Create Subnets
resource "aws_subnet" "subnet"{

    count = length(var.subnetCIDRblock)

    cidr_block = var.subnetCIDRblock[count.index]

    vpc_id = aws_vpc.vpc.id
    availability_zone = var.availabilityZone[count.index]
    map_public_ip_on_launch = true

    tags = {
        Name = "My_Subnet${count.index}"
    }
}

# Create the Internet Gateway
resource "aws_internet_gateway" "igw" {

    vpc_id = aws_vpc.vpc.id

    tags = {
        Name = "My_InternetGateway"
    }
}

# Create the Route Table
resource "aws_default_route_table" "route_table" {

    default_route_table_id = aws_vpc.vpc.default_route_table_id

    tags = {
        Name = "My_RouteTable"
    }
}

# Create the Internet Access
resource "aws_route" "vpc_internet_access" {

  route_table_id = aws_default_route_table.route_table.id
  destination_cidr_block = var.destinationCIDRblock
  gateway_id = aws_internet_gateway.igw.id

}

# Associate the Route Table with the Subnets
resource "aws_route_table_association" "subnetAssociation" {

    count = length(var.subnetCIDRblock)
    subnet_id = element(aws_subnet.subnet.*.id, count.index)
    route_table_id = aws_default_route_table.route_table.id

}

# Create the Security Group
resource "aws_default_security_group" "vpc_security_group" {
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
        Name = "My_VPC_Security_Group"
        Description = "My VPC Security Group"
    }
}

