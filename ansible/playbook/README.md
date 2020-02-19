---
title:
subtitle:
---

# Hetzner playbooks

## hetzner-init-context

Initializes local hcloud context.

Parameters:

| Variable | Required | Meaning |
| --- | --- | --- |
| hetzner_context_name | x | context name |
| hetzner_token | x | The token to register with Hetzner. |

```bash
$ ansible-playbook playbook/hetzner-create-hcloud-server.yml
```

## create hcloud server

Variables used:

| Variable | Required | Default | Meaning |
| --- | --- | --- | --- |
| vm_name | x | | Name of the VM to be created at hetzner. |
| server_type | | cx31 | Server type. The list can be obtained using `hcloud server-type list`. Usually cx31 |
| vm_image | | centos-7 | Hetzner image to be used as source (centos-7,...) | 
| salt_text | x | | Salt and pepper. |
| password_text | x | | Password of the created user |
| hetzner_context_name |  | Context name for hcloud |
| vm_delete |  | | Deletes the VM prior to creating it |

```bash
$ ansible-playbook playbook/hetzner-create-hcloud-server.yml
```