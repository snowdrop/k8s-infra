Role Name
=========

Delete an existing Hetzner SSH key.

Requirements
------------

1. `hcloud` Hetzner CLI installed and on the PATH.

Role Variables
--------------

The following variables are required:
* vm_name: Name of the SSH key to be removed.

Dependencies
------------

Example Playbook
----------------

```yaml
- name: "Delete ssh key"
  hosts: localhost
  gather_facts: yes

  pre_tasks:
    - name: "Set default hetzner_context_name if it is not defined"
      set_fact:
        hetzner_context_name: "snowdrop"
      when: hetzner_context_name is not defined

    - name: "Validate required variables"
      assert:
        that:
          - "vm_name is defined"
        fail_msg: "'vm_name' must be defined"

  tasks:
    - name: "Activate hetzner context"
      include_role:
        name: "hetzner/activate_context"
      vars:
        context_name: "{{ hetzner_context_name }}"

    - include_role:
        name: hetzner/delete_ssh_key
      vars:
        vm_name: "{{ vm_name }}"
...
```

Author Information
------------------

This role has been created by the Snowdrop team.
