variable "env" {
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
