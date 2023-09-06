Role Name
=========

CRUD operations for GoDaddy DNS records.

Requirements
------------

N/A

Role Variables
--------------

**Variables** defined at `defaults/main.yml`.

| Variable | Description
| --- | ---
| `pro_api_url` | URL for the GoDaddy production API
| `ote_api_url` | URL for the GoDaddy OTE (Open Transaction Environment) API
| `domains_folder` | API URI folder for the domains
| `dns_records_folder` | API URI folder for the DNS records

**Parameters**

| Parameter | DNS Description
| --- | ---
| `api_environment`<br/><span style="color:fuchsia">string</span> | GoDaddy API environment to use:<ul><li>_Empty/Default_: OTE</li><li>`production` or `prod`: Production</li></ul>
| `state`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | State of the record: <ul><li>`present`</li><li>`absent`</li></ul>
| `domain_name`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy domain to associate the DNS record with. 
| `record_type`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | DNS type of the record
| `record_name`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | Name of the DNS record
| `dns`<br/><span style="color:fuchsia">json</span><br/><span style="color:red">required</span> | DNS data

The contents of the `dns` variables are the following.

```json
[
  {
    "data": "string",
    "port": 65535,
    "priority": 0,
    "protocol": "string",
    "service": "string",
    "ttl": 0,
    "weight": 0
  }
]
```

| Parameter | Description
| --- | ---
| `data`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API environment to use:<ul><li>_Empty/Default_: OTE</li><li>`production` or `prod`: Production</li></ul>
| `priority`<br/><span style="color:fuchsia">integer</span> | Check the GoDaddy API documentation
| `priority`<br/><span style="color:fuchsia">integer</span> | Check the GoDaddy API documentation
| `protocol`<br/><span style="color:fuchsia">string</span> | Check the GoDaddy API documentation
| `service`<br/><span style="color:fuchsia">string</span> | Check the GoDaddy API documentation
  `ttl`<br/><span style="color:fuchsia">json</span> | Check the GoDaddy API documentation
| `weight`<br/><span style="color:fuchsia">integer</span> | Check the GoDaddy API documentation
  `ttl`<br/><span style="color:fuchsia">integer</span> | Check the GoDaddy API documentation

**Authentication information**

| Parameter | DNS Description
| --- | ---
| `api_key`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API key.
| `api_secret`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API secretkey.
The role returns the `godaddy_dns` variable with the results of the process.

Dependencies
------------

N/A.

Example Playbook
----------------

Create a DNS record.

```yaml
- name: "GoDaddy DNS create"
  hosts: localhost
  gather_facts: True
    
  tasks:
    - name: "Create DNS record"
      include_role:
        name: "snowdrop.godaddy.dns"
      vars: 
        state: "present"
```

```bash
ansible-playbook ansible/playbook/godaddy/godaddy_dns_create_passwordstore.yml \ 
  -e domain_name="<existing_domain>" \ 
  -e record_type="<dns_record_type>" \ 
  -e record_name="<dns_record_name" \ 
  -e '{"dns": {"data": "<ip_address>"}}' \ 
  -e api_environment=prod
```

Example for adding a `A` record for `mydomain` at `snowdrop.dev`.

```bash
ansible-playbook ansible/playbook/godaddy/godaddy_dns_create_passwordstore.yml \ 
  -e domain_name="snowdrop.dev" \ 
  -e record_type="A" \ 
  -e record_name="mydomain" \ 
  -e '{"dns": {"data": "127.0.0.1"}}' \ 
  -e api_environment=prod
```

License
-------

[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

Author Information
------------------

RedHat Snowdrop team.
