{
  "Resources": {
    "ECSAutoScalingGroup1":{
      "Type":"AWS::AutoScaling::AutoScalingGroup",
      "Properties":{
        "VPCZoneIdentifier":["${SubnetId}"],
        "LaunchConfigurationName":{
          "Ref":"ContainerInstances1"
        },
        "MinSize": "1",
        "MaxSize": "1",
        "DesiredCapacity":"1",
        "Tags": [ {
          "Key": "Name",
          "Value": "${EcsClusterName}",
          "PropagateAtLaunch": "true"
        } ]
      },
      "CreationPolicy":{
        "ResourceSignal":{
          "Timeout":"PT15M"
        }
      },
      "UpdatePolicy":{
        "AutoScalingReplacingUpdate":{
          "WillReplace":"true"
        }
      }
    },
    "ContainerInstances1":{
      "Type":"AWS::AutoScaling::LaunchConfiguration",
      "Properties":{
        "ImageId":"${AMIID}",
        "SecurityGroups":["${SecurityGroup}"],
        "InstanceType":"${InstanceType}",
        "IamInstanceProfile":"${IamInstanceProfile}",
        "KeyName":"${KeyName}",
        "UserData":{
          "Fn::Base64":{
            "Fn::Join":[
              "",
              [
                "#!/bin/bash\n",
                "echo ECS_CLUSTER=${EcsClusterName}",
                " >> /etc/ecs/ecs.config\n",
                "yum -y install python27-pip\n",
                "yum install -y jq\n",
                "pip install --upgrade awscli\n",
                "pip install boto3\n",
                "/usr/local/bin/aws s3 cp ${CertsS3Bucket} /home/ec2-user/openvpn/certs.tar.gz\n",
                "/usr/local/bin/aws s3 cp ${MonitorScriptS3Bucket} /home/ec2-user/monitor-OpenVPN-status.py\n",
                "echo \"*/1     *       *       *       *       /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 10 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 20 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 30 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 40 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 50 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "sudo tar zxvf /home/ec2-user/openvpn/certs.tar.gz -C /home/ec2-user/openvpn\n",
                "instanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)\n",
                "REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)\n",
                "/usr/local/bin/aws ec2 modify-instance-attribute --region $REGION --instance-id $instanceID --source-dest-check '{\"Value\": false}'\n",
                "/usr/local/bin/aws ec2 associate-address --region $REGION --instance-id $instanceID --allocation-id ${EIPAllocationId1}\n",
                "yum install -y aws-cfn-bootstrap\n",
                "/opt/aws/bin/cfn-signal -e $? ",
                "         --stack ",
                {
                  "Ref":"AWS::StackName"
                },
                "         --resource ECSAutoScalingGroup1 ",
                "         --region ",
                {
                  "Ref":"AWS::Region"
                },
                "\n"
              ]
            ]
          }
        }
      }
    },

    "ECSAutoScalingGroup2":{
      "Type":"AWS::AutoScaling::AutoScalingGroup",
      "Properties":{
        "VPCZoneIdentifier":["${SubnetId}"],
        "LaunchConfigurationName":{
          "Ref":"ContainerInstances2"
        },
        "MinSize": "1",
        "MaxSize": "1",
        "DesiredCapacity":"1",
        "Tags": [ {
          "Key": "Name",
          "Value": "${EcsClusterName}",
          "PropagateAtLaunch": "true"
        } ]
      },
      "CreationPolicy":{
        "ResourceSignal":{
          "Timeout":"PT15M"
        }
      },
      "UpdatePolicy":{
        "AutoScalingReplacingUpdate":{
          "WillReplace":"true"
        }
      }
    },
    "ContainerInstances2":{
      "Type":"AWS::AutoScaling::LaunchConfiguration",
      "Properties":{
        "ImageId":"${AMIID}",
        "SecurityGroups":["${SecurityGroup}"],
        "InstanceType":"${InstanceType}",
        "IamInstanceProfile":"${IamInstanceProfile}",
        "KeyName":"${KeyName}",
        "UserData":{
          "Fn::Base64":{
            "Fn::Join":[
              "",
              [
                "#!/bin/bash\n",
                "echo ECS_CLUSTER=${EcsClusterName}",
                " >> /etc/ecs/ecs.config\n",
                "yum -y install python27-pip\n",
                "yum install -y jq\n",
                "pip install --upgrade awscli\n",
                "pip install boto3\n",
                "/usr/local/bin/aws s3 cp ${CertsS3Bucket} /home/ec2-user/openvpn/certs.tar.gz\n",
                "/usr/local/bin/aws s3 cp ${MonitorScriptS3Bucket} /home/ec2-user/monitor-OpenVPN-status.py\n",
                "echo \"*/1     *       *       *       *       /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 10 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 20 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 30 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 40 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "echo \"*/1     *       *       *       *       /bin/sleep 50 ; /usr/bin/python /home/ec2-user/monitor-OpenVPN-status.py ${InternalServiceIP}\" >> /var/spool/cron/ec2-user\n",
                "sudo tar zxvf /home/ec2-user/openvpn/certs.tar.gz -C /home/ec2-user/openvpn\n",
                "instanceID=$(curl http://169.254.169.254/latest/meta-data/instance-id)\n",
                "REGION=$(curl --silent http://169.254.169.254/latest/dynamic/instance-identity/document | jq -r .region)\n",
                "/usr/local/bin/aws ec2 modify-instance-attribute --region $REGION --instance-id $instanceID --source-dest-check '{\"Value\": false}'\n",
                "/usr/local/bin/aws ec2 associate-address --region $REGION --instance-id $instanceID --allocation-id ${EIPAllocationId2}\n",
                "yum install -y aws-cfn-bootstrap\n",
                "/opt/aws/bin/cfn-signal -e $? ",
                "         --stack ",
                {
                  "Ref":"AWS::StackName"
                },
                "         --resource ECSAutoScalingGroup2 ",
                "         --region ",
                {
                  "Ref":"AWS::Region"
                },
                "\n"
              ]
            ]
          }
        }
      }
    }
  }
}
