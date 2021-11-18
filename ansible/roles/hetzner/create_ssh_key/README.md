Role Name
=========

Create a new Hetzner SSH key.

Requirements
------------

1. `hcloud` Hetzner CLI installed and on the PATH.

Role Variables
--------------

The following variables are required:
* override_public_key: Instead of using the passwordstore Hetzner RSA key use the one provided in this variable

Optional variables
* hetzner_context_name: Hetzner context to use. Will default to `snowdrop` if no context is provided.


Dependencies
------------

Example Playbook
----------------

```yaml
- name: "Create hetzner SSH key"
  hosts: "a_host"
  gather_facts: "{{ gathering_host_info | default('true') | bool == true }}"

  tasks:
    - include_role:
        name: hetzner/create_ssh_key
      vars:
        vm_name: "{{ hetzner_context_name }}"
...
```

Author Information
------------------

This role has been created by the Snowdrop team.
