Role Name
=========

Generate Ansible inventory files for a server.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

The following variables are required:
* type: Host type. Should be one of:
  * cloud
  * hetzner
  * simple

* vm_name: Name of the vm being created, for hetzner hosts
* os_user: Name of the user being used to connect to the server (hetzner hosts)
* ip_address: IP Address of the host
* new_ssh_port_number: Used for changing the default ssh port (hetzner hosts)

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
