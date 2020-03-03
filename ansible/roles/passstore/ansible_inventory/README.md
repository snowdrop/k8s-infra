Role Name
=========

Obtains the keys for a server in a pass database.

The structure of the database used is the following:

```
\ l2: provider
  |
  \ l3: host
    |
    \ os_user: user to be created at OS level
    \ os_password: password of the os_user
    \ os_password: password of the os_user
    \ ssh_port: custom ssh port to be used in ssh connections
    \ id_rsa: RSA pivate key in PEM format
    \ id_rsa.pub: RSA public key in OpenSSH format
```

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

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
