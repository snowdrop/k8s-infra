#!/usr/bin/python

ANSIBLE_METADATA = {
    'metadata_version': '1.1'
}

DOCUMENTATION = '''
---
module: openshift_version

short_description: Simple module providing information about the Openshift version

description:
    - "Extracts the information of the oc version command"

options:

'''

EXAMPLES = '''
# Pass in a message
- name: Get openshift version
  openshift_version_out:

'''

RETURN = '''
server:
    description: The server version
    type: str
client:
    description: The client version
    type: str
'''

import subprocess
import re

from ansible.errors import AnsibleError
from ansible.module_utils.basic import AnsibleModule
from ansible.module_utils._text import to_native, to_text


def run_module():
    # define the available arguments/parameters that a user can pass to the module
    module_args = dict()

    # seed the result dict in the object
    result = dict(
        changed=False,
        server_full='',
        server='',
        client_full='',
        client=''
    )

    # the AnsibleModule object will be our abstraction working with Ansible
    # this includes instantiation, a couple of common attr would be the
    # args/params passed to the execution, as well as if the module
    # supports check mode
    module = AnsibleModule(
        argument_spec=module_args,
        supports_check_mode=True
    )

    # if the user is working with this module in only check mode we do not
    # want to make any changes to the environment, just return the current
    # state with no modifications
    if module.check_mode:
        return result

    # Execute the actual command and process output
    _populate_results(result)

    module.exit_json(**result)


def _populate_results(result):
    cmd = 'oc version'
    p = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    cmd_output, err = p.communicate()
    if p.returncode:
        raise AnsibleError('Openshift version check (%s) failed: %s' % (to_native(cmd), to_native(err)))

    # The cmd_output above should like something like:
    '''
oc v3.9.0-alpha.3+78ddc10
kubernetes v1.9.1+a0ce1bc657
features: Basic-Auth GSSAPI Kerberos SPNEGO

Server https://192.168.99.50:8443
openshift v3.9.0-alpha.3+78ddc10
kubernetes v1.9.1+a0ce1bc657    
    '''

    for line in to_text(cmd_output, errors='surrogate_or_strict').split(u'\n'):
        if line.startswith('oc '):
            result['client_full'], result['client'] = _extract_versions(line.split()[1])
        elif line.startswith('openshift '):
            result['server_full'], result['server'] = _extract_versions(line.split()[1])


'''
Extracts the full version as well the part of version without the git commit
'''


def _extract_versions(line):
    full = re.sub(u'[^0-9a-zA-Z\-+.]', u'', line)
    plus_index = full.find('+')
    if 0 < plus_index:
        return full, full[1:plus_index]
    return full, full


def main():
    run_module()


if __name__ == '__main__':
    main()
