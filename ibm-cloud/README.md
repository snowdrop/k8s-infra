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

The goal of this project is to maintain IBM Cloud VPC

## References

* https://www.ibm.com/cloud/blog/announcements/ibm-cloud-collection-for-ansible
* https://github.com/IBM-Cloud/ansible-collection-ibm
* https://registry.terraform.io/providers/IBM-Cloud/ibm/latest/docs/resources/is_subnet


## Install 

Download and insall the Ansible collection.

```bash
$ ansible-galaxy collection install ibm.cloudcollection
```

### Create API Key

his playbooks requires that an IBM Cloud API key is available.

Using the [API Keys section](https://cloud.ibm.com/iam/apikeys) of the web site, create a new API key.

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

The VPC playbooks gather information from the `vpc-vars.yml` variables file. The variables used are the following:

| Variable | Value | Description |
| --- | --- | --- |
| **name_prefix** | `snowdrop` | Prefix used in the different resources. |
| **zone** | `eu-de-1` | Zone where the resources will be created. |
| **ipv4_cidr_block** | `10.243.0.0/24` | The IPv4 range of the subnet. |

#### Create a new VPC

Create a new VPC.

```bash
$ ansible-playbook vpc-create.yml
```

This command will also create a VPC Subnet.

#### Destroy an existing VPC

Destry an existing VPC and it's subnets.

```bash
$ ansible-playbook vpc-destroy.yml
```

### VSI - Virtual Server Instance

TODO

