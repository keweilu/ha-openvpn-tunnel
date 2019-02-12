variable "aws_region" {}

variable "DeploymentName" {
  type = "string"
  description = "A name to describe the terraform deployment"
  default = "OpenVPN-Server"
}
variable "EcsClusterName" {
  type = "string"
  description = "The ECS Cluster Name"
}
variable "EcrRepoUrl" {
  type = "string"
  description = "The image ecr repo url for the OpenVPN server"
}
variable "ImageTag" {
  type = "string"
  description = "The image tag for the OpenVPN server"
}
variable "DnsServers" {
  type = "string"
  description = "A string containing a list of DNS servers that are presented to the container, delimited by comma"
}
variable "DnsSearchDomains" {
  type = "string"
  description = "A string containing a list of DNS search domains that are presented to the container, delimited by comma"
}
variable "KeyName" {
  type = "string"
  description = "Name of an existing EC2 KeyPair to enable SSH access to the ECS instances."
}
variable "VpcId" {
  type = "string"
  description = "A VPC that allows instances to access the Internet."
}

variable "ClientCidrBlock" {
  type = "list"
  description = "A list of network subnet CIDR blocks that your OpenVPN clients are in"
  default = []
}

variable "k8sWorkerSecurityGroup" {
  type = "string"
  description = "The security group ID of the worker nodes of the k8s cluster"
}
variable "SubnetId" {
  type = "string"
  description = "A subnet in your selected VPC."
}
variable "CertsS3Bucket" {
  type = "string"
  default = "s3://OpenVPN/certs.tar.gz"
  description = "The S3 bucket to pull the OpenVPN certs from."
}

variable "MonitorScriptS3Bucket" {
  type = "string"
  default = "s3://scripts/monitor-OpenVPN-status.py"
  description = "The S3 bucket to pull the scripts to generate OpenVPN connection status and publish to cloudwatch."
}

variable "InternalServiceIP" {
  type = "string"
  description = "An internal service IP that will be ping from the OpenVPN server to check the status of the connection."
}
variable "InstanceType" {
  type = "string"
  default = "t3.micro"
  description = "EC2 instance type for the OpenVPN server"
}
variable "amis" {
   type = "map"
   default = {
     ca-central-1 = "ami-fc5fe798"
     us-east-1 = "ami-20ff515a"
     us-east-2 = "ami-b0527dd5"
     us-west-1 = "ami-b388b4d3"
     us-west-2 = "ami-3702ca4f"
     eu-west-1 = "ami-d65dfbaf"
     eu-central-1 = "ami-ebfb7e84"
     ap-northeast-1 = "ami-95903df3"
     ap-southeast-1 = "ami-c8c98bab"
     ap-southeast-2 = "ami-e3b75981"
   }
}
