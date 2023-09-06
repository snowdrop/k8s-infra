Role Name
=========

CRUD operations for GoDaddy domains.

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
| `agreements_folder` | API URI folder for the agreements service
| `domains_folder` | API URI folder for the domains service
| `purchase_folder` | API URI folder for the purchase service

**Authentication information**

| Parameter | DNS Description
| --- | ---
| `api_key`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API key.
| `api_secret`<br/><span style="color:fuchsia">string</span><br/><span style="color:red">required</span> | GoDaddy API secretkey.

Dependencies
------------

N/A

Example Playbook
----------------

TBD

License
-------

[Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0)

Author Information
------------------

RedHat Snowdrop team.
