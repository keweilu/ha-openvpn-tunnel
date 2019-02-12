data "template_file" "container_definition" {
  template = "${file("${path.module}/templates/container-definition.json.tpl")}"
  vars {
    EcrRepoUrl = "${var.EcrRepoUrl}"
    ImageTag = "${var.ImageTag}"
    DnsServers = "${jsonencode(split(",", var.DnsServers))}"
    DnsSearchDomains = "${jsonencode(split(",", var.DnsSearchDomains))}"
  }
}

data "template_file" "cloudformation_asg" {
  template = "${file("${path.module}/templates/cloudformation-asg.json.tpl")}"
  vars {
    AMIID = "${lookup(var.amis, var.aws_region)}"
    SecurityGroup = "${aws_security_group.EcsSecurityGroup.id}"
    InstanceType = "${var.InstanceType}"
    IamInstanceProfile = "${aws_iam_instance_profile.ecs_ec2_iam_profile.id}"
    KeyName = "${var.KeyName}"
    SubnetId = "${var.SubnetId}"
    EcsClusterName = "${var.EcsClusterName}"
    CertsS3Bucket = "${var.CertsS3Bucket}"
    MonitorScriptS3Bucket = "${var.MonitorScriptS3Bucket}"
    InternalServiceIP = "${var.InternalServiceIP}"
    EIPAllocationId1 = "${aws_eip.EIPAddress1.id}"
    EIPAllocationId2 = "${aws_eip.EIPAddress2.id}"
  }
}

resource "aws_ecs_cluster" "ECSCluster" {
  name = "${var.EcsClusterName}"
}

resource "aws_eip" "EIPAddress1" {
  vpc = true
}

resource "aws_eip" "EIPAddress2" {
  vpc = true
}

resource "aws_security_group" "EcsSecurityGroup" {
  description = "${var.DeploymentName}-Terraform"
  ingress {
    from_port   = 1194
    to_port     = 1194
    protocol    = "udp"
    cidr_blocks = "${var.ClientCidrBlock}"
  }
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    security_groups = ["${var.k8sWorkerSecurityGroup}"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
  vpc_id = "${var.VpcId}"
  tags {
    Name = "${var.DeploymentName}-terraform"
  }
}

resource "aws_ecs_task_definition" "taskdefinition" {
  family = "${var.DeploymentName}-terraform"
  volume {
    name      = "certs"
    host_path = "/home/ec2-user/openvpn/certs"
  }
  container_definitions = "${data.template_file.container_definition.rendered}"
  network_mode = "host"
}

resource "aws_ecs_service" "service" {
  name = "${var.DeploymentName}-terraform"
  cluster = "${aws_ecs_cluster.ECSCluster.id}"
  deployment_maximum_percent = 100
  deployment_minimum_healthy_percent = 50
  desired_count = 2
  placement_constraints {
    type = "distinctInstance"
  }
  ordered_placement_strategy {
    type  = "spread"
    field = "instanceId"
  }
  task_definition = "${aws_ecs_task_definition.taskdefinition.arn}"
}

resource "aws_iam_role" "ECSEC2Role" {
  name = "${var.DeploymentName}-Terraform"
  assume_role_policy = "${file("${path.module}/templates/ecs-ec2-role.json")}"
}

resource "aws_iam_role_policy" "ECSEC2Policy" {
  policy = "${file("${path.module}/templates/ecs-ec2-policy.json")}"
  role = "${aws_iam_role.ECSEC2Role.id}"
}

resource "aws_iam_instance_profile" "ecs_ec2_iam_profile" {
  path = "/"
  role = "${aws_iam_role.ECSEC2Role.name}"
}

resource "aws_cloudformation_stack" "autoscaling_groups" {
  name = "${var.DeploymentName}-ECS-ASG-terraform"
  tags {
    Name = "${var.DeploymentName}-terraform"
  }
  template_body = "${data.template_file.cloudformation_asg.rendered}"
}
