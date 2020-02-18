---
title:
subtitle:
---

# Hetzner playbooks

## hetzner-init-context

Initializes local hcloud context.

Parameters:

| Variable | Default | Meaning |
| --- | --- | --- |
| hetzner_context_name |  | context name |
| hetzner_token |  | The token to register with Hetzner. |

```bash
$ ansible-playbook playbook/hetzner-create-hcloud-server.yml
```

## create hcloud server

Parameters:

| Variable | Default | Meaning |
| --- | --- | --- |
| vm_name |  | Name of the VM to be created at hetzner. |
| server_type | cx41 | Server type. The list can be obtained using `hcloud server-type list` |
| vm_image | centos-7 | Hetzner image to be used as source | 
| salt_text | | Salt and pepper |
| password_text |  | Password of the created user |
| hetzner_context_name |  | context name |
| vm_delete |  | Deletes the VM prior to creating it |

```bash
$ ansible-playbook playbook/hetzner-create-hcloud-server.yml
```