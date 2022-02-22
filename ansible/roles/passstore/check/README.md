Role Name
=========

Checks that `pass` is installed and the passwordstore database is correctly set.

Requirements
------------

This playbook requires the following variables to be informed:

| Variable | Default | Description |
| --- | --- | --- |
| pass_l1 | snowdrop | pass_db_name |
| pass_l2 | hetzner | Host provider [hetzner, ...] |
| pass_l3 |  | Virtual Machine name |  

Role Variables
--------------

N/A

Dependencies
------------

N/A

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

```yaml
- name: "Check the passwordstore installation"
  hosts: localhost
  gather_facts: no

  tasks:
  - name: "Check passwordstore installation"
    include_role:
      name: "passstore/check"
    tags: [always]
```

Author Information
------------------

This role has been created by the Snowdrop team
