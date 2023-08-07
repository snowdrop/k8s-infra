Role Name
=========

Collects information related to a domain.

Requirements
------------

N/A

Role Variables
--------------

**Parameters**

| Parameter | DNS Description
| --- | ---
| `api_environment`<br/><span style="color:fuchsia">string</span> | GoDaddy API environment to use:<ul><li>_Empty/Default_: OTE</li><li>`production` or `prod`: Production</li></ul>
| `domain_name`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy domain to associate the DNS record with. 

**Authentication information**

| Parameter | DNS Description
| --- | ---
| `api_key`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API key.
| `api_secret`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API secretkey.

The role returns the `godaddy_domain_info` variable with the information obtained from GoDaddy.

Dependencies
------------

N/A

Example Playbook
----------------

Get information from a Domain.

```yaml
- name: "GoDaddy Domain information"
  hosts: localhost
  gather_facts: True
    
  tasks:
    - name: "Get domain information"
      include_role:
        name: "snowdrop.godaddy.domain_info"

    - name: "Print domain information"
      debug:
        var: godaddy_domain_info
```

Example call of this playbook requesting domain information.

```bash
ansible-playbook ansible/playbook/godaddy/godaddy_domain_info_passwordstore.yml \ 
  -e domain_name="snowdrop.dev" \ 
  -e api_environment=prod
```



License
-------

[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

Author Information
------------------

RedHat Snowdrop team.
