variable "DeploymentName" {
  type = "string"
  description = "A name to describe the terraform deployment"
  default = "OpenVPN-RT-Update-Staging"
}
variable "EcsClusterName" {
  type = "string"
  description = "The ECS Cluster Name"
}
variable "PrimaryOpenVPNServer" {
  type = "string"
  description = "The primary OpenVPN server"
}
variable "RoutetableId" {
  type = "string"
  description = "The route table ID that is associated with the EC2 instances from which you want to access your internal Internal network"
}

variable "InternalCidrBlock" {
  type = "list"
  description = "A list of your internal network subnet CIDR blocks"
  default = []
}

variable "LambdaS3Bucket" {
  type = "string"
  description = "The S3 bucket to pull the route table update code from."
}
variable "LambdaS3CodePath" {
  type = "string"
  description = "The S3 bucket path to pull the route table update code from."
}
