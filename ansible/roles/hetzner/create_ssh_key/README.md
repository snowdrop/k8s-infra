Role Name
=========

Provision a new hetzner server using the API (`hcloud`)

Requirements
------------

1. The Hetzner Cloud ssh key already exists.

Role Variables
--------------

The following variables are required:
* vm_name: Name of the vm being started

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

This role has been created by the Snowdrop team
