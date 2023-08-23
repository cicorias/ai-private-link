# Overview
Provides a Terraform deployment for Azure illustrating Application Insights from a Private Link 

The intended audience is for internal applications that emit Application Insights telemetry.

## Deployment
While this makes use of Terraform, the tool [Task - aka go-task](https://taskfile.dev/) to help with the commands

### Requirements
This has only been tested in a WSL2 environment under Ubuntu 22.04

## Network Configuration

using ipcalc:

```shell
➜  terraform git:(main) ✗ ipcalc 10.42.42.0/22  --s 256 256
Address:   10.42.42.0           00001010.00101010.001010 10.00000000
Netmask:   255.255.252.0 = 22   11111111.11111111.111111 00.00000000
Wildcard:  0.0.3.255            00000000.00000000.000000 11.11111111
=>
Network:   10.42.40.0/22        00001010.00101010.001010 00.00000000
HostMin:   10.42.40.1           00001010.00101010.001010 00.00000001
HostMax:   10.42.43.254         00001010.00101010.001010 11.11111110
Broadcast: 10.42.43.255         00001010.00101010.001010 11.11111111
Hosts/Net: 1022                  Class A, Private Internet

1. Requested size: 256 hosts
Netmask:   255.255.254.0 = 23   11111111.11111111.1111111 0.00000000
Network:   10.42.40.0/23        00001010.00101010.0010100 0.00000000
HostMin:   10.42.40.1           00001010.00101010.0010100 0.00000001
HostMax:   10.42.41.254         00001010.00101010.0010100 1.11111110
Broadcast: 10.42.41.255         00001010.00101010.0010100 1.11111111
Hosts/Net: 510                   Class A, Private Internet

2. Requested size: 256 hosts
Netmask:   255.255.254.0 = 23   11111111.11111111.1111111 0.00000000
Network:   10.42.42.0/23        00001010.00101010.0010101 0.00000000
HostMin:   10.42.42.1           00001010.00101010.0010101 0.00000001
HostMax:   10.42.43.254         00001010.00101010.0010101 1.11111110
Broadcast: 10.42.43.255         00001010.00101010.0010101 1.11111111
Hosts/Net: 510                   Class A, Private Internet

Needed size:  1024 addresses.
Used network: 10.42.40.0/22
Unused:
```