#! /usr/bin/python

from os import walk, listdir, environ
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

# print("password_store_dir: " + password_store_dir)

f = []

# def a(dirpath, arrdirnames, filenames): walk('/home/ajc102/dev/client/redhat-snowdrop/passstore/snowdrop')

# print (a)

for (dirpath, dirnames, filenames) in walk(password_store_dir):
#  for dirnames in listdir(password_store_dir):
# for dirnames in next(walk(password_store_dir))[1]:
    # print("dirpath: "+dirpath)
    # print(dirnames)
    for (dirname) in dirnames:
        # print("dirname: "+dirname)
        if (dirname in ['hetzner','openstack']):
            # print(dirname + " it's an inventory folder!!! Lets dig in " + password_store_dir + '/' + dirname)
            result[dirname] = {}
            result[dirname]['hosts'] = []
            for (provDirPath, provDirNames, provFileNames) in walk(password_store_dir + '/' + dirname):
                # print("provDirPath: "+provDirPath)
                # print(provDirNames)
                for (provDirName) in provDirNames:
                    # print("provDirName: "+provDirName)
                    if (provDirName not in ['openshift-accounts', 'console']):
                        result[dirname]['hosts'].append(provDirName)
                        # print("its a host!!!")
                        for (hostDirPath, hostDirNames, hostFileNames) in walk(password_store_dir + '/' + dirname + '/' + provDirName):
                            # result[dirname]['hosts'][provDirName] = {}
                            # result[dirname]['hosts'][provDirName]['hosts'] = []
                            host_vars = {'ansible_ssh_private_key_file':'~/.ssh/id_rsa_snowdrop_' + dirname + '_' + provDirName}
                            # print(hostFileNames)
                            for (hostFileName) in hostFileNames:
                                passEntryName = hostFileName.split('.')[0]
                                if ('id_rsa' not in passEntryName and 'os_password' not in passEntryName):
                                    passEntry = dirname +'/' + provDirName + '/' + passEntryName
                                    # print(hostFileName)
                                    # print('passEntry: ' + passEntry)
                                    pipe = Popen(['pass', 'show', passEntry], stdout=PIPE, universal_newlines=True)
                                    passLines = pipe.stdout.readlines()
                                    passEntry = passLines[0].replace('\n', '')
                                    # print(passLines[0])
                                    if ('os_user' == passEntryName):
                                        host_vars.update({'ansible_user':passEntry})
                                    elif ('ip_address' == passEntryName):
                                        host_vars.update({'ansible_ssh_host':passEntry})
                                    elif ('ssh_port' == passEntryName):
                                        host_vars.update({'ansible_ssh_port':passEntry})
                                    else:
                                        host_vars.update({passEntryName:passEntry})

                        result['_meta']['hostvars'].update({provDirName:host_vars})
                break

    # f.extend(filenames)
    # print('dirpath' + dirpath)
    # print(dirnames)
    # print(filenames)
    break

# pipe = Popen(['zoneadm', 'list', '-ip'], stdout=PIPE, universal_newlines=True)

# result['all']['vars']['ansible_connection'] = ansible_connection

# print(result)

if len(sys.argv) == 2 and sys.argv[1] == '--list':
    print(json.dumps(result))
# elif len(sys.argv) == 3 and sys.argv[1] == '--host':
    # print(json.dumps({'ansible_connection': ansible_connection}))
else:
    sys.stderr.write("Need an argument, either --list or --host <host>\n")