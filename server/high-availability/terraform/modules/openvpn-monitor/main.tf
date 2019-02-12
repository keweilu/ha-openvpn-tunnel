data "aws_s3_bucket_object" "LambdaCodeFile" {
  bucket = "${var.s3_bucket}"
  key    = "${var.s3_key}"
}

resource "aws_lambda_function" "SlackNotifierLambda" {
  function_name = "${var.DeploymentName}-Terraform"
  handler = "index.handler"
  runtime = "nodejs4.3"
  s3_bucket = "${var.s3_bucket}"
  s3_key = "${var.s3_key}"
  source_code_hash = "${data.aws_s3_bucket_object.LambdaCodeFile.version_id}"
  role = "${aws_iam_role.LambdaRole.arn}"
  timeout = "60"
  environment {
    variables = {
      SLACK_CHANNEL = "${var.slack_channel}"
      SLACK_USERNAME = "${var.slack_username}"
      UNENCRYPTED_HOOK_URL = "${var.unencrypted_hook_url}"
    }
  }
  tags {
    Name = "${var.DeploymentName}-Terraform"
  }
}

resource "aws_iam_role" "LambdaRole" {
  name = "${var.DeploymentName}-lambda-execution-Terraform"
  assume_role_policy = "${file("${path.module}/templates/lambda-execution-role.json")}"
}

resource "aws_iam_role_policy" "LambdaRolePolicy" {
  policy = "${file("${path.module}/templates/lambda-execution-policy.json")}"
  role = "${aws_iam_role.LambdaRole.id}"
}

resource "aws_sns_topic" "CloudWatchNotificationsSNS" {
  name = "${var.DeploymentName}-Terraform"
  display_name = "${var.DeploymentName}-Terraform"
}

resource "aws_sns_topic_subscription" "SlackNotifierSubscription" {
  topic_arn = "${aws_sns_topic.CloudWatchNotificationsSNS.arn}"
  protocol = "lambda"
  endpoint = "${aws_lambda_function.SlackNotifierLambda.arn}"
}

resource "aws_lambda_permission" "InvokeBySNS" {
  statement_id  = "AllowExecutionFromSNS"
  action = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.SlackNotifierLambda.function_name}"
  principal = "sns.amazonaws.com"
  source_arn = "${aws_sns_topic.CloudWatchNotificationsSNS.arn}"
}

resource "aws_cloudwatch_metric_alarm" "OpenVPNServer1" {
  alarm_name = "OpenVPN Server ${var.elasticIP_1} liveness"
  alarm_description = "Status of OpenVPN Server ${var.elasticIP_1}"
  alarm_actions = ["${aws_sns_topic.CloudWatchNotificationsSNS.arn}"]
  ok_actions = ["${aws_sns_topic.CloudWatchNotificationsSNS.arn}"]
  namespace = "OpenVPN"
  dimensions {
    Public_IP = "${var.elasticIP_1}"
  }
  metric_name = "Status"
  statistic = "Minimum"
  threshold = "1"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  period = "10"
  treat_missing_data = "breaching"
}

resource "aws_cloudwatch_metric_alarm" "OpenVPNServer2" {
  alarm_name = "OpenVPN Server ${var.elasticIP_2} liveness"
  alarm_description = "Status of OpenVPN Server ${var.elasticIP_2}"
  alarm_actions = ["${aws_sns_topic.CloudWatchNotificationsSNS.arn}"]
  ok_actions = ["${aws_sns_topic.CloudWatchNotificationsSNS.arn}"]
  namespace = "OpenVPN"
  dimensions {
    Public_IP = "${var.elasticIP_2}"
  }
  metric_name = "Status"
  statistic = "Minimum"
  threshold = "1"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  period = "10"
  treat_missing_data = "breaching"
}
