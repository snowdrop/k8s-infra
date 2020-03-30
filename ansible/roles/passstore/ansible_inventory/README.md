Role Name
=========

Obtains the keys for a server in a pass database.

The structure of the database used is the following:

```
├── l2: provider
|   ├── l3: host
│   │   ├── ansible_ssh_host: host name or IPV4 address for the host. Used by Ansible to perform ssh connections
│   │   ├── ansible_ssh_port: ssh port used by Ansible in the connections
│   │   ├── groups
│   │   │   ├── k8s_115
│   │   │   └── masters
│   │   │   └── other_ansible_groups
│   │   ├── id_rsa: RSA pivate key in PEM format
│   │   ├── id_rsa.pub: RSA public key in OpenSSH format
│   │   ├── os_password: password of the os_user
│   │   ├── os_user: user to be created at OS level
│   │   └── ssh_port: custom ssh port to be used in ssh connections
```

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

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
