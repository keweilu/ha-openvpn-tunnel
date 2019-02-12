[
  {
    "Name": "openvpn-server",
    "Image": "${EcrRepoUrl}:${ImageTag}",
    "memoryReservation": 900,
    "PortMappings": [
      {
        "ContainerPort": 1194,
        "Protocol": "udp"
      }
    ],
    "DnsServers": ${DnsServers},
    "DnsSearchDomains": ${DnsSearchDomains},
    "MountPoints": [
      {
        "SourceVolume": "certs",
        "ContainerPath": "/etc/openvpn/certs",
        "ReadOnly": true
      }
    ],
    "Privileged": true
  }
]
