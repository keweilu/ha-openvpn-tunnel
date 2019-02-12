# Monitor OpenVPN connection status and publish metrics to cloudwatch

import json
import os
import requests
import sys

import boto3

# The IP 169.254.169.254 is used in Amazon EC2 to retrieve instance metadata
_meta_base_url = 'http://169.254.169.254/'

class OpenVPNStatusMonitor():

  # get the status of OpenVPN connection by ping a service in your internal network
  def get_status(self, hostname):
    response = os.system("ping -c 1 -W 2 " + hostname)
    self.status = 1 if response == 0 else 0

  # publish the status metrics to cloudwatch
  def publish_metric(self):
    response = requests.get(_meta_base_url+'latest/dynamic/instance-identity/document')
    data = json.loads(response.text)
    region = data['region']
    response = requests.get(_meta_base_url+'latest/meta-data/public-ipv4')
    public_ipv4 = response.text
    cloudwatch_client = boto3.client('cloudwatch', region_name=region)
    response = cloudwatch_client.put_metric_data(
      Namespace='OpenVPN',
      MetricData=[
        {
          'MetricName': 'Status',
          'Dimensions': [
            {
              'Name': 'Public_IP',
              'Value': public_ipv4
            }
          ],
          'Value': self.status,
          'StorageResolution': 1
        }
      ]
    )

if __name__ == "__main__":
   monitor = OpenVPNStatusMonitor()
   monitor.get_status(sys.argv[1])
   monitor.publish_metric()
