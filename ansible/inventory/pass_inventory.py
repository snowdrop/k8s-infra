#! /usr/bin/python

# -*- coding:utf-8 -*-
# This module reads information from a passwordstore database and turns it into an ansible dynamic inventory.

"""
This module reads information from a passwordstore database and turns it into an ansible dynamic inventory.

It gathers information on the passwordstore directory, from the `PASSWORD_STORE_DIR` environment variable.

It assumes that the passwordstore database us organized into the following layers

+ --- providers_1 (hetzner)
|      + --- host_1
|      |     + variable_1
|      |     + variable_2
|      |     + variable_3
|      |
|      + --- host_2
|            |
|            + variable_1
|            + variable_2
|            + variable_3
+ --- providers_2 (openstak)
+ --- ansible/inventory
       + --- group_1
       |     + host_1
       |     + host_2
       |     + host_3
       |
       + --- group_2
             |
             + host_1
             + host_3
             + host_4

"""
from os import walk, listdir, environ, path
from subprocess import Popen, PIPE
import sys
import json

result = {}
result['all'] = {}
result['all']['hosts'] = []
result['all']['vars'] = {}
result['_meta'] = {}
result['_meta']['hostvars'] = {}
# ansible_connection = 'passwordstore'
password_store_dir = environ.get('PASSWORD_STORE_DIR')

f = []

# Navigate through the passwordstore folder
for (dirpath, dirnames, filenames) in walk(password_store_dir):
    for (dirname) in dirnames:
        # Filter the folders that might contain hosts.
        if (dirname in ['hetzner','openstack']):
            result[dirname] = {}
            result[dirname]['hosts'] = []
            # list all folders inside a provider
            for (provDirPath, provDirNames, provFileNames) in walk(password_store_dir + '/' + dirname):
                for (provDirName) in provDirNames:
                    # Filter out subfolders that don't contain hosts
                    if (provDirName not in ['openshift-accounts', 'console']):
                        result[dirname]['hosts'].append(provDirName)
                        # Get all hosts for that provider.
                        for (hostDirPath, hostDirNames, hostFileNames) in walk(password_store_dir + '/' + dirname + '/' + provDirName):
                            # Init host_vars variable with the location of the SSH RSA Private Key
                            host_vars = {'ansible_ssh_private_key_file':'~/.ssh/id_rsa_snowdrop_' + dirname + '_' + provDirName}
                            for (hostFileName) in hostFileNames:
                                passEntryName = hostFileName.split('.')[0]
                                # Esclude some entries that won't be included in the inventory
                                if ('id_rsa' not in passEntryName and 'os_password' not in passEntryName):
                                    passEntry = dirname +'/' + provDirName + '/' + passEntryName
                                    pipe = Popen(['pass', 'show', passEntry], stdout=PIPE, universal_newlines=True)
                                    passLines = pipe.stdout.readlines()
                                    passEntry = passLines[0].replace('\n', '')
                                    if ('os_user' == passEntryName):
                                        host_vars.update({'ansible_user':passEntry})
                                    elif ('ip_address' == passEntryName):
                                        host_vars.update({'ansible_ssh_host':passEntry})
                                    # elif ('ssh_port' == passEntryName):
                                    #     host_vars.update({'ansible_ssh_port':passEntry})
                                    else:
                                        host_vars.update({passEntryName:passEntry})
                                    # for (hostDirName) in hostDirNames:
                                    #     if (provDirName not in ['openshift-accounts', 'console']):
                            for (hostGroupDirPath, hostGroupDirNames, hostGroupFileNames) in walk(path.join(hostDirPath, 'groups')):
                                for (hostGroupFileName) in hostGroupFileNames:
                                    hostGroupFileName = hostGroupFileName.split('.')[0]
                                    # print(hostGroupFileName)
                                    if (not hostGroupFileName in result):
                                        result[hostGroupFileName] = {}
                                        result[hostGroupFileName]['hosts'] = []
                                    result[hostGroupFileName]['hosts'].append(provDirName)
                            break
                        result['_meta']['hostvars'].update({provDirName:host_vars})
                break
        # ansible folder
        # elif (dirname == 'ansible'):
        #     for (ansibleInventoryDirPath, ansibleInventoryGroupNames, ansibleInventoryFileNames) in walk(password_store_dir + '/ansible/inventory'):
        #         # Each folder is an ansible group
        #         for (ansibleInventoryGroupName) in ansibleInventoryGroupNames:
        #             result[ansibleInventoryGroupName] = []
        #             # Each file inside a group is a host belonging to that group.
        #             for (hostDirPath, subgroupDirNames, hostFileNames) in walk(password_store_dir + '/ansible/inventory/' + ansibleInventoryGroupName):
        #                 # for (subgroupDirName) in subgroupDirNames:
        #                 #     if (subgroupDirName == 'vars' ):
        #                 #         TODO: Process group variables in here
        #                 #     else
        #                 #         TODO: Process as subgroup folder
        #                 for (hostFileName) in hostFileNames:
        #                     result[ansibleInventoryGroupName].append(hostFileName.split('.')[0])
        #             break
        #     break
    break

if len(sys.argv) == 2 and sys.argv[1] == '--list':
    print(json.dumps(result))
elif len(sys.argv) == 3 and sys.argv[1] == '--host':
    print(json.dumps(result['_meta']['hostvars'][sys.argv[2]]))
else:
    sys.stderr.write("Need an argument, either --list or --host <host>\n")
