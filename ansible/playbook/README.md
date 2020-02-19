---
title:
subtitle:
---

# Hetzner playbooks

## hetzner-init-context

Initializes local hcloud context.

Parameters:

| Variable | Required | Prompt | Meaning |
| --- | :---: | :---: | --- |
| hetzner_context_name | x | x | context name |
| hetzner_token | x | x | The token to register with Hetzner. |

```bash
$ ansible-playbook playbook/hetzner-init-context.yml
```

## create hcloud server

Variables used:

| Variable | Required | Default | Prompt | Meaning |
| --- | :---: | :---: | :---: | --- |
| vm_name | x | | x | Name of the VM to be created at hetzner. |
| server_type | | cx31 |  | Server type. The list can be obtained using `hcloud server-type list`. Usually cx31 |
| vm_image | | centos-7 |  | Hetzner image to be used as source (centos-7,...) | 
| salt_text | x | | x | Salt and pepper. |
| password_text | x | | x | Password of the created user. |
| hetzner_context_name | x | | x | Context name for hcloud. |
| vm_delete |  | False |  | Deletes the VM prior to creating it. |

```bash
$ ansible-playbook playbook/hetzner-create-hcloud-server.yml
```

Optionally, using environment variables:

```bash
$ ansible-playbook playbook/hetzner-create-hcloud-server.yml -e '{ "vm_name": "my-name" }' -e '{ "salt_text": "<my salt>" }' -e '{ "password_text": "<my password>" }' -e '{ "hetzner_context_name": "<context name>" }' -e '{ "vm_delete": True }' -e '{ "pass_store_dir": "/home/<my home>/.my-password-store" }'
```
