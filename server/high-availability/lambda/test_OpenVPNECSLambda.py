import unittest

import boto3
import json
from moto import mock_ecs, mock_ec2
from moto.ec2 import utils as ec2_utils
from sets import Set
import sure

import OpenVPNECSLambda

@mock_ecs
@mock_ec2
class TestOpenVPNECSLambda(unittest.TestCase):

  # create fake AWS resources and set up the testing AWS environment
  def setUp(self):
    self.ecs_client = boto3.client('ecs', region_name='ca-central-1')
    self.ec2_client = boto3.client('ec2', region_name='ca-central-1')
    self.ec2 = boto3.resource('ec2', region_name='ca-central-1')

    # create a VPC
    self.vpc = self.ec2_client.create_vpc(CidrBlock='172.12.0.0/16')
    # create a route table
    self.route_table = self.ec2_client.create_route_table(VpcId=self.vpc['Vpc']['VpcId'])

    # create the OpenVPN ECS cluster
    self.test_cluster_name = 'test_ecs_cluster'
    self.ecs_client.create_cluster(
      clusterName=self.test_cluster_name
    )

    # create two instances and register them to the OpenVPN ECS cluster
    instance_to_create = 2
    self.test_instance_ids = []
    for i in range(0, instance_to_create):
      test_instance = self.ec2.create_instances(
        ImageId='ami-1234abcd',
        MinCount=1,
        MaxCount=1,
      )[0]
      self.instance_id_document = json.dumps(
        ec2_utils.generate_instance_identity_document(test_instance)
      )
      response = self.ecs_client.register_container_instance(
        cluster=self.test_cluster_name,
        instanceIdentityDocument=self.instance_id_document
      )
      self.test_instance_ids.append(response['containerInstance']['ec2InstanceId'])

    # create the internal cidr route entries
    self.internal_ip_cidrs = [
      '1.0.0.0/8',
      '2.0.0.0/8',
      '3.0.0.0/8'
    ]
    for cidr in self.internal_ip_cidrs:
      self.ec2_client.create_route(
        RouteTableId=self.route_table['RouteTable']['RouteTableId'],
        DestinationCidrBlock=cidr,
        InstanceId=self.test_instance_ids[0]
      )

  def test_get_second_instance_id(self):
    OpenVPNECSLambda._ecs_cluster_name = self.test_cluster_name
    OpenVPNECSLambda._primary_ecs_container_instance = self.test_instance_ids[0]

    secondary_instance_id = OpenVPNECSLambda.get_second_instance_id(self.ecs_client)
    secondary_instance_id.should.equal(self.test_instance_ids[1])

  def test_update_route_table(self):
    OpenVPNECSLambda._route_table_id = self.route_table['RouteTable']['RouteTableId']
    OpenVPNECSLambda.update_route_table(self.ec2_client, self.test_instance_ids[1])

    response = self.ec2_client.describe_route_tables(
      RouteTableIds = [self.route_table['RouteTable']['RouteTableId']]
    )

    instanceIds = Set([route['InstanceId'] for route in response['RouteTables'][0]['Routes'] if route['DestinationCidrBlock'] in self.internal_ip_cidrs])

    instanceIds.should.have.length_of(1)
    instanceIds.should.contain(self.test_instance_ids[1])

  # moto does not support lambda.update_function_configuration yet
  # https://github.com/spulec/moto/blob/master/IMPLEMENTATION_COVERAGE.md
  # Add test_lambda_handler after lambda.update_function_configuration is supported by moto
  # def test_lambda_handler(self):

if __name__ == '__main__':
  unittest.main()
