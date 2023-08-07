Role Name
=========

Collects information related to a domain DNS records.

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
| `domain_name`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy domain to associate the DNS record with. 
| `record_type`<br/><span style="color:fuchsia">string</span> | DNS type of the record
| `record_name`<br/><span style="color:fuchsia">string</span> | Name of the DNS record

**Authentication information**

| Parameter | DNS Description
| --- | ---
| `api_key`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API key.
| `api_secret`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API secretkey.

The role returns the `godaddy_dns_info` variable with the information obtained from GoDaddy.

Dependencies
------------

N/A

Example Playbook
----------------

Get information from a DNS record.

```yaml
- name: "GoDaddy DNS information"
  hosts: localhost
  gather_facts: True
    
  tasks:
    - name: "Get DNS record for domain"
      include_role:
        name: "snowdrop.godaddy.dns_info"

    - name: "Print DNS information"
      debug:
        var: godaddy_dns_info
```

Example of requesting all DNS records for a specific domain.

```bash
ansible-playbook ansible/playbook/godaddy/godaddy_dns_info_passwordstore.yml -e domain_name="snowdrop.dev"
```

Example requesting information for specific DNS `record_type` and `record_name`.

```bash
ansible-playbook ansible/playbook/godaddy/godaddy_dns_info_passwordstore.yml -e domain_name="snowdrop.dev" -e api_environment=prod -e record_type=A -e record_name="mysubdomain"
```


License
-------

[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

Author Information
------------------

RedHat Snowdrop team.
