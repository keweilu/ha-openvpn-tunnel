import ConfigParser
import json
import logging
import os

import boto3

_primary_ecs_container_instance = None
_route_table_id = None
_ecs_cluster_name = None
_lambda_function_name = None

logging.basicConfig()
_logger = logging.getLogger(__name__)
_logger.setLevel(logging.INFO)

_config = ConfigParser.ConfigParser()
_config.read("config.ini")

def initialize():
  global _primary_ecs_container_instance
  global _route_table_id
  global _ecs_cluster_name
  global _lambda_function_name
  _primary_ecs_container_instance = os.environ.get('Primary_EC2')
  _route_table_id = os.environ.get('Route_Table_ID')
  _ecs_cluster_name = os.environ.get('ECS_Cluster_Name')
  _lambda_function_name = os.environ.get('Lambda_Function_Name')

def get_second_instance_id(ecs_client):
  instance_ids = []

  # list all the container instance arns of the OpenVPN ECS cluster
  container_instance_arns = ecs_client.list_container_instances(cluster=_ecs_cluster_name)

  # get detail information of each container instance
  instance_details = ecs_client.describe_container_instances(
    cluster=_ecs_cluster_name,
    containerInstances=container_instance_arns['containerInstanceArns']
  )

  for instance in instance_details['containerInstances']:
    if instance['ec2InstanceId'] != _primary_ecs_container_instance:
      instance_ids.append(instance['ec2InstanceId'])

  if not instance_ids:
    raise ValueError('Error: Did not find a secondary OpenVPN Server Instance!')
  return instance_ids[0]

def update_route_table(ec2_client, secondary_instance_id):
  internal_ip_cidrs = _config.get('internal', 'ip_cidr').split(',')
  for cidr in internal_ip_cidrs:
    response = ec2_client.delete_route(
      RouteTableId=_route_table_id,
      DestinationCidrBlock=cidr
    )
    response = ec2_client.create_route(
      RouteTableId=_route_table_id,
      DestinationCidrBlock=cidr,
      InstanceId=secondary_instance_id
    )
    if not response['Return']:
      raise ValueError('Error: Failed to update route entry ' + cidr + ' for ' + _route_table_id)

  _logger.info('Successfully updated the route table!')

def lambda_handler(event, context):
  initialize()
  if event['source'] != 'aws.ecs':
    raise ValueError('Error: Function only supports input from events with a source type of: aws.ecs')

  _logger.info('Receive Event:')
  _logger.info(json.dumps(event))

  # if one OpenVPN server is down
  if event['detail']['lastStatus'] == 'STOPPED':
    ecs_client = boto3.client('ecs', region_name = event['region'])
    ec2_client = boto3.client('ec2', region_name = event['region'])
    lambda_client = boto3.client('lambda', region_name = event['region'])

    # Get the instance id on which the OpenVPN server stopped
    stopped_instance = ecs_client.describe_container_instances(
      cluster=_ecs_cluster_name,
      containerInstances=[event['detail']['containerInstanceArn'].split('/')[1]]
    )
    if stopped_instance['failures']:
      _logger.info(type(stopped_instance['failures']))
      raise ValueError('Error: Describe container instance failure!')
    stopped_instance_id = stopped_instance['containerInstances'][0]['ec2InstanceId']

    # If the primary OpenVPN Server is down, promote the secondary OpenVPN server as the
    # primary and update the route table
    # If the secondary OpenVPN server is down, do nothing, a new secondary OpenVPN server will be
    # automatically started
    if stopped_instance_id == _primary_ecs_container_instance:
      _logger.info('The Primary OpenVPN Server ' + stopped_instance_id + ' is down!')
      secondary_instance_id = get_second_instance_id(ecs_client)

      # Update route table
      update_route_table(ec2_client, secondary_instance_id)

      # Promote the secondary as the primary
      response = lambda_client.update_function_configuration(
        FunctionName=_lambda_function_name,
        Environment={
          'Variables': {
            'Primary_EC2': secondary_instance_id,
            'Route_Table_ID': _route_table_id,
            'ECS_Cluster_Name': _ecs_cluster_name,
            'Lambda_Function_Name': _lambda_function_name
          }
        }
      )
      if response['ResponseMetadata']['HTTPStatusCode'] != 200:
        raise ValueError('Error: Failed to promote the secondary as the primary!')
      else:
        _logger.info('Successfully promoted the secondary OpenVPN server as the primary')
    else:
      _logger.info('The Secondary OpenVPN Server is down, No action needed!')
