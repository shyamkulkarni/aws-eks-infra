variable "project_name" { 
  type        = string  
  default     = "eks-gitops"
  description = "Project name for resource naming"
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}
variable "region" {
  type    = string
  default = "us-east-1"
}
variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}
variable "az_count" {
  type    = number
  default = 3
}
variable "domain_name" {
  type    = string
  default = "example.com"  # Hosted in Route53
}
variable "public_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.0.0/20","10.0.16.0/20","10.0.32.0/20"]
}
variable "private_subnet_cidrs" {
  type    = list(string)
  default = ["10.0.128.0/20","10.0.144.0/20","10.0.160.0/20"]
}
# Node group sizes
variable "ng_on_demand_min" {
  type    = number
  default = 1
}
variable "ng_on_demand_max" {
  type    = number
  default = 15
}
variable "ng_on_demand_desired" {
  type    = number
  default = 10
}

variable "ng_spot_enabled" {
  type    = bool
  default = true
}
variable "ng_spot_min" {
  type    = number
  default = 0
}
variable "ng_spot_max" {
  type    = number
  default = 6
}
variable "ng_spot_desired" {
  type    = number
  default = 0
}

variable "instance_types_on_demand" {
  type    = list(string)
  default = ["t4g.medium"]
}
variable "instance_types_spot" {
  type    = list(string)
  default = ["t4g.large","m6g.large"]
}

# Tags
variable "tags" {
  type = map(string)
  default = {
    "Project" = "eks-gitops"
    "Owner"   = "you"
    "Env"     = "dev"
  }
}