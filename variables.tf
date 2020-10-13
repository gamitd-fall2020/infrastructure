variable "region" {
     type = string
     default = "us-east-1"
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
     type = string
     default = "10.0.0.0/16"
}
variable "subnetCIDRblock" {
     type = list
     default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "availabilityZone" {
     type = list
     default = ["us-east-1a", "us-east-1b", "us-east-1c"]
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
