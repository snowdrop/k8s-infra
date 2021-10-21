# IBM Cloud VPC

## Table of Contents

   * [References](#references)
   * [Install](#install)
      * [Create API Key](#create-api-key)
   * [Usage Guide](#usage-guide)
      * [VPC - Virtual Private Cloud](#vpc---virtual-private-cloud)
         * [Create a new VPC](#create-a-new-vpc)
         * [Destroy an existing VPC](#destroy-an-existing-vpc)
      * [VSI - Virtual Server Instance](#vsi---virtual-server-instance)


## Introduction

The goal of this project is to manage IBM Cloud VPC (Virtual Private cloud)

## References

* https://www.ibm.com/cloud/blog/announcements/ibm-cloud-collection-for-ansible
* https://github.com/IBM-Cloud/ansible-collection-ibm
* https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_subnet


## Install 

Download and install the IBM Ansible collection.

```bash
$ ansible-galaxy collection install ibm.cloudcollection
```

### Create API Key

These playbooks require that an IBM Cloud API key exists.

Using the [API Keys section](https://cloud.ibm.com/iam/apikeys) of the IBM Cloud web site, create a new API key.

## Usage Guide

Before using these playbooks, make sure that the following environment variables are defined.

Export the API key using the `IC_API_KEY` environment variable:

```bash
export IC_API_KEY=<YOUR_API_KEY_HERE>
```

e.g.

```bash
export IC_API_KEY=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Export the IBM Cloud region using the `IC_REGION` environment variable:

```bash
export IC_REGION=<REGION_NAME_HERE>
```

e.g.

```bash
export IC_REGION=eu-de
```

### VPC - Virtual Private Cloud

The VPC playbooks gather the information from the `vpc-vars.yml` variables file. The variables used are the following:

| Variable | Value | Description |
| --- | --- | --- |
| **name_prefix** | `snowdrop` | Prefix used to name the different resources. |
| **zone** | `eu-de-1` | Zone where the resources will be created. |
| **ipv4_cidr_block** | `10.243.0.0/24` | The IPv4 range of the subnet. |

#### Create a new VPC

Create a new VPC.

```bash
$ ansible-playbook vpc-create.yml
```

This command will also create a VPC Subnet.

To get the VPC information use the `vpc-info` playbook.

e.g.

```bash
$ ansible-playbook vpc-info.yml 

PLAY [Describe IBM Cloud VPC information] **************************************

TASK [Gathering Facts] *********************************************************
Thursday 21 October 2021  12:47:08 +0200 (0:00:00.011)       0:00:00.011 ****** 
ok: [localhost]

TASK [Fetch the variables from var file] ***************************************
Thursday 21 October 2021  12:47:09 +0200 (0:00:01.010)       0:00:01.021 ****** 
ok: [localhost]

TASK [Get the vpc details] *****************************************************
Thursday 21 October 2021  12:47:09 +0200 (0:00:00.020)       0:00:01.042 ****** 
ok: [localhost]

TASK [Print VPC facts] *********************************************************
Thursday 21 October 2021  12:47:20 +0200 (0:00:10.187)       0:00:11.230 ****** 
ok: [localhost] => {
    "msg": {
        "classic_access": false,
        "crn": "crn:v1:bluemix:public:is:eu-de:a/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::vpc:xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "cse_source_addresses": [
            {
                "address": "0.0.0.0",
                "zone_name": "eu-de-1"
            },
            {
                "address": "0.0.0.0",
                "zone_name": "eu-de-2"
            },
            {
                "address": "0.0.0.0",
                "zone_name": "eu-de-3"
            }
        ],
        "default_network_acl": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "default_network_acl_crn": "crn:v1:bluemix:public:is:eu-de:a/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::network-acl:xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "default_network_acl_name": "xxxx-xxxx-xxxx-xxxx",
        "default_routing_table": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "default_routing_table_name": "xxxx-xxxx-xxxx-xxxx",
        "default_security_group": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "default_security_group_crn": "crn:v1:bluemix:public:is:eu-de:a/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::security-group:xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "default_security_group_name": "xxxx-xxxx-xxxx-xxxx",
        "id": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "name": "snowdrop-vpc",
        "resource_controller_url": "https://cloud.ibm.com/vpc-ext/network/vpcs",
        "resource_crn": "crn:v1:bluemix:public:is:eu-de:a/xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx::vpc:xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
        "resource_group": "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
        "resource_group_name": "Default",
        "resource_name": "snowdrop-vpc",
        "resource_status": "available",
        "security_group": [
            {
                "group_id": "rxxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
                "group_name": "xxxx-xxxx-xxxx-xxxx",
                "rules": [
                    {
                        "code": 0,
                        "direction": "outbound",
                        "ip_version": "ipv4",
                        "port_max": 0,
                        "port_min": 0,
                        "protocol": "all",
                        "remote": "0.0.0.0/0",
                        "rule_id": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
                        "type": 0
                    },
                    {
                        "code": 0,
                        "direction": "inbound",
                        "ip_version": "ipv4",
                        "port_max": 0,
                        "port_min": 0,
                        "protocol": "all",
                        "remote": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
                        "rule_id": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
                        "type": 0
                    }
                ]
            }
        ],
        "status": "available",
        "subnets": [
            {
                "available_ipv4_address_count": 251,
                "id": "xxxx-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxx",
                "name": "snowdrop-subnet",
                "status": "available",
                "total_ipv4_address_count": 256,
                "zone": "eu-de-1"
            }
        ],
        "tags": []
    }
}

PLAY RECAP ***************************************************************************
localhost                  : ok=4    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

Thursday 21 October 2021  12:47:20 +0200 (0:00:00.047)       0:00:11.277 ****** 
=============================================================================== 
Get the vpc details ------------------------------------------ 10.19s
Gathering Facts ----------------------------------------------- 1.01s
Print VPC facts ----------------------------------------------- 0.05s
Fetch the variables from var file ----------------------------- 0.02s

```

#### Destroy an existing VPC

Destroy an existing VPC and it's subnets.

```bash
$ ansible-playbook vpc-destroy.yml
```

### VSI - Virtual Server Instance

TODO

