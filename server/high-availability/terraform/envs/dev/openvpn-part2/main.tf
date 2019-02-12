provider "aws" {
  region = "us-west-2"
}

module "route_update_lambda" {
  source = "../../../modules/route-update-lambda"

  DeploymentName = ""
  EcsClusterName = ""
  PrimaryOpenVPNServer = ""
  RoutetableId = ""
  InternalCidrBlock = []
  LambdaS3Bucket = ""
  LambdaS3CodePath = ""
}
