Role Name
=========

Add bash_alias to the user profile and updates it's contents.

Requirements
------------

None.

Role Variables
--------------

| Name | Type | Values | Description |
| --- | --- | --- | --- |
| state | string | [present, absent] | Installs the bash_aliases, or removes it |
| operation | string | [add, remove] | Adds or removes aliases |

Dependencies
------------

None.

Example Playbook
----------------

Install the bash_alias functionality.

```yaml
- hosts: "{{ vm_name | default('localhost') }}"
  gather_facts: true

  tasks:
    - name: "Install bash_alias"
      include_role:
        name: "tools/bash_alias"
      vars:
        state: present
```

Add one alias to the bash_alias.

```yaml
- hosts: "{{ vm_name | default('localhost') }}"
  gather_facts: true

  tasks:
    - name: "Add alias to bash_alias"
      include_role:
        name: "tools/bash_alias"
      vars:
        operation: "add"
        name: "kc"
        command: "/usr/bin/kubectl"

```

Have generic playbook...

```yaml
- hosts: "{{ vm_name | default('localhost') }}"
  gather_facts: true

  tasks:
    - name: "Add alias to bash_alias"
      include_role:
        name: "tools/bash_alias"
```

... which is completed from the command line with playbook command line parameters, for instance:

```bash
$ ansible-playbook playbook/tools/bash_alias.yml -e "operation='add'" -e "name='kc'" -e "command=/usr/bin/kubectl"
```

Author Information
------------------

This role has been created by the Snowdrop team.
