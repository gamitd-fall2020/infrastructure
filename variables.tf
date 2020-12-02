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
}
variable "subnetCIDRblock" {
     description = "Enter Appropriate Subnet Cidr Block"
     type = list
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
     description = "Enter S3 Bucket Name"
     type = string
}
variable "rdsInstanceIdentifier"{
     description = "Enter RDS Instance Identifier"
     type = string
}
variable "rdsDBName"{
     description = "Enter RDS DB Name"
     type = string
}
variable "rdsUsername"{
     description = "Enter RDS User Name"
     type = string
}
variable "rdsPassword"{
     description = "Enter RDS Password"
     type = string
}
variable "dynamoDBName"{
     description = "Enter DynamoDB Name"
     type = string
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
variable "domainName"{
     description = "Enter Domain Name"
     type = string
}
variable "fromAddress"{
     type = string
}