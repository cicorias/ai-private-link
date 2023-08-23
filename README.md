# Overview
Provides a Terraform deployment for Azure illustrating Application Insights.

The intended audience is for internal applications that emit Application Insights telemetry.

>NOTE: the private link part is not enabled as it requires feature enablement.


## Parts
The main parts of this is a Virtual Machine along with a Bastion that uses your local `~/ssh/id_rsa.pub` ssh credentials if they are there - otherwise it fails.

Once deployed, the `cloud-config` runs a script that emits an event and trace every 10 seconds.

The script isis here: [app/sendAIEvent.sh](app/sendAIEvent.sh)

## Deployment
While this makes use of Terraform, the tool [Task - aka go-task](https://taskfile.dev/) to help with the commands

### Requirements
This has only been tested in a WSL2 environment under Ubuntu 22.04
- Terraform
- Task - [Task - aka go-task](https://taskfile.dev/)
- a ssh key pair as `~/.ssh/id_rsa`


### Run Task cli

If you run `task` from the `./terraform` folder you will see what commands are available.

```shell
Choose a task to run
task: Available tasks for this project:
* apply:                   Apply terraform
* clean:                   Clean terraform
* enablePrivateLink:       Enable Private Link on azure
* init:                    Initialize terraform
* kill:                    force remove resources
```

#### Essentially

##### `task apply`
At this point, you can observe Application Insights or Log Analytics Custom Events and Traces -- these are called `traces` and `customevent` in Application Insights tables, but in Log Analytics they are `AppTraces` and `AppCustomEvents`.

##### `task clean`
This does a proper terraform destroy, clean state and lock files

##### `task kill`
For the impatient, this will delete the Azure Resource group and clean up terraform state and lock files

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