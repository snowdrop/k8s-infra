
# Introduction

Ansible playbook to deploy the `snowdrop-bot` into k8s using [quay.io](https://quay.io/) registry.

# Playbook

This project consists of 2 playbooks:
* [build](#build): builds the project
* [deploy](#deploy): deploys the application to [quay.io](https://quay.io/) and restarts the k8s pod

## build

This playbook builds the application. It's optional if it is already build locally.

```bash
$ ansible-playbook snowdrop-bot/ansible/build.yml -e bot_version=0.6-SNAPSHOT -e build_folder=/z/dev/client/redhat-snowdrop/forks-github/snowdrop-bot -e skip_dw=true
```

| variable | prompt | default | description |
| --- | --- | --- | --- |
| bot_version | yes |  | Version to be applied to the `snowdrop-bot` tag at [quay.io](https://quay.io/). |
| build_folder | no | `/tmp/snowdrop-bot-deployment/{{ bot_version }}/` | Folder containing the built `snowdrop-bot`. |
| skip_dw | no |  | When set to `true` the project won't be downloaded from [github](https://github.com/snowdrop-bot/snowdrop-bot) |

## deploy

This playbook deploys the `snowdrop-bot` by performing the following tasks:
1. Create local image
1. Push image to [quay.io](https://quay.io/) with 2 tags, one for the version and another for the `latest`
1. Scale down and up again the pod (the pod must be deployed against the `latest` version)

```bash
$ ansible-playbook snowdrop-bot/ansible/deploy.yml -e bot_version=0.6-SNAPSHOT -e build_folder=/z/dev/client/redhat-snowdrop/forks-github/snowdrop-bot -e quay_io_user=antcosta -e kube_cli_tool=/x/dev/apps/kubectl-1.14.9/kubectl -e kube_config=~/.kube/config
```

The following variables are used an can be overriden.

| variable | prompt | default | description |
| --- | --- | --- | --- |
| bot_version | yes |  | Version to be applied to the `snowdrop-bot` tag at [quay.io](https://quay.io/). |
| build_folder | no | `/tmp/snowdrop-bot-deployment/{{ bot_version }}/` | Folder containing the built `snowdrop-bot`. |
| kube_cli_tool | no | `kubectl` | `kubectl` executable. |
| kube_config | no | | Location of the kube config file. |
| quay_io_user | yes | | User used to login to [quay.io](https://quay.io/). |
| quay_io_password | yes | | Password used to login to [quay.io](https://quay.io/). |

