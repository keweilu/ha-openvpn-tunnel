data "aws_s3_bucket_object" "LambdaCodeFile" {
  bucket = "${var.LambdaS3Bucket}"
  key    = "${var.LambdaS3CodePath}"
}

resource "aws_lambda_function" "OpenVPNRouteUpdateLambda" {
  function_name    = "${var.DeploymentName}-Terraform"
  handler          = "OpenVPNECSLambda.lambda_handler"
  runtime          = "python2.7"
  s3_bucket        = "${var.LambdaS3Bucket}"
  s3_key           = "${var.LambdaS3CodePath}"
  source_code_hash = "${data.aws_s3_bucket_object.LambdaCodeFile.version_id}"
  role             = "${aws_iam_role.OpenVPNRouteUpdateLambdaRole.arn}"
  timeout          = "60"

  environment {
    variables = {
      Route_Table_ID       = "${var.RoutetableId}"
      ECS_Cluster_Name     = "${var.EcsClusterName}"
      Lambda_Function_Name = "${var.DeploymentName}-Terraform"
      Primary_EC2          = "${var.PrimaryOpenVPNServer}"
    }
  }

  tags {
    Name = "${var.DeploymentName}-Terraform"
  }
}

resource "aws_cloudwatch_event_rule" "OpenVPNRouteUpdateRule" {
  name        = "${var.DeploymentName}-Terraform"
  description = "Update Routing Table based on OpenVPN server status"

  event_pattern = <<PATTERN
    {
      "source": [
        "aws.ecs"
      ],
      "detail-type": [
        "ECS Task State Change"
      ]
    }
  PATTERN

  is_enabled = true
}

resource "aws_cloudwatch_event_target" "lambda" {
  rule      = "${aws_cloudwatch_event_rule.OpenVPNRouteUpdateRule.name}"
  target_id = "${var.DeploymentName}-Terraform"
  arn       = "${aws_lambda_function.OpenVPNRouteUpdateLambda.arn}"
}

resource "aws_lambda_permission" "InvokeByRule" {
  statement_id  = "AllowExecutionFromCloudWatchRule"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.OpenVPNRouteUpdateLambda.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.OpenVPNRouteUpdateRule.arn}"
}

resource "aws_iam_role" "OpenVPNRouteUpdateLambdaRole" {
  name               = "${var.DeploymentName}-Terraform"
  assume_role_policy = "${file("${path.module}/templates/iam-role.json")}"
}

resource "aws_iam_role_policy" "OpenVPNRouteUpdateLambdaPolicy" {
  policy = "${file("${path.module}/templates/iam-role-policy.json")}"
  role   = "${aws_iam_role.OpenVPNRouteUpdateLambdaRole.id}"
}

resource "aws_route" "InternalRoute" {
  count                  = "${length(var.InternalCidrBlock)}"

  route_table_id         = "${var.RoutetableId}"
  destination_cidr_block = "${element(var.InternalCidrBlock, count.index)}"
  instance_id            = "${var.PrimaryOpenVPNServer}"
}
