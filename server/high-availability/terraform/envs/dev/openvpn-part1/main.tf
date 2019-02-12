provider "aws" {
  region = "us-west-2"
}

module "openvpn_server" {
  source = "../../../modules/openvpn-server"

  aws_region             = ""
  DeploymentName         = ""
  EcsClusterName         = ""
  EcrRepoUrl             = ""
  ImageTag               = ""
  KeyName                = ""
  VpcId                  = ""
  ClientCidrBlock        = []
  k8sWorkerSecurityGroup = ""
  SubnetId               = ""
  CertsS3Bucket          = ""
  MonitorScriptS3Bucket  = ""
  InternalServiceIP      = ""
  InstanceType           = ""
  DnsServers             = ""
  DnsSearchDomains       = ""
}

module "openvpn_monitor" {
  source = "../../../modules/openvpn-monitor"

  DeploymentName       = ""
  elasticIP_1          = "${module.openvpn_server.EIPAddress1}"
  elasticIP_2          = "${module.openvpn_server.EIPAddress2}"
  s3_bucket            = ""
  s3_key               = ""
  slack_channel        = ""
  slack_username       = ""
  unencrypted_hook_url = ""
}
