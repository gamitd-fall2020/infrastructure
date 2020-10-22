variable "profile" {
     description = "Enter AWS Environment"
     type        = string
}
variable "region" {
     description = "Enter AWS Region"
     type = string
}
variable "vpcName" {
     description = "Enter VPC Name"
     type = string
}
variable "dnsSupport" {
     type = string
     default = true
}
variable "dnsHostNames" {
     type = string
     default = true
}
variable "vpcCIDRblock" {
     description = "Enter VPC Cidr Block"
     type = string
     default = "10.0.0.0/16"
}
variable "subnetCIDRblock" {
     description = "Enter Appropriate Subnet Cidr Block"
     type = list
     default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}
variable "destinationCIDRblock" {
    default = "0.0.0.0/0"
}
variable "ingressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "egressCIDRblock" {
    type = list
    default = [ "0.0.0.0/0" ]
}
variable "S3BucketName" {
      type = string
      default = "webapp.deep.gamit"
}
variable "rdsInstanceIdentifier"{
     type = string
     default = "csye6225-f20"
}
variable "rdsDBName"{
     type = string
     default = "csye6225"
}
variable "rdsUsername"{
     type = string
     default = "csye6225fall2020"
}
variable "rdsPassword"{
     description = "Enter RDS Password"
     type = string
}
variable "dynamoDBName"{
     type = string
     default = "csye6225"
}
variable "aws_ssh_key"{
     description = "SSH Key Name"
     type = string
}
variable "application_port"{
     type = string
     default = "3000"
}
variable "accountId"{
     description = "Enter Dev Account ID"
     type = string
}