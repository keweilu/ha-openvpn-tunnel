variable "DeploymentName" {
  type = "string"
  description = "A name to describe the terraform deployment"
  default = "OpenVPN-Monitor"
}
variable "elasticIP_1" {
  type = "string"
  description = "Elastic IP of OpenVPN Server 1"
}
variable "elasticIP_2" {
  type = "string"
  description = "Elastic IP of OpenVPN Server 2"
}

variable "s3_bucket" {
  type = "string"
  description = "The S3 bucket to pull the slack alert code from."
}
variable "s3_key" {
  type = "string"
  description = "The S3 bucket path to pull the slack alert code from."
}
variable "slack_channel" {
  type = "string"
  description = "Slack Channel to post messages."
}
variable "slack_username" {}
variable "unencrypted_hook_url" {}
