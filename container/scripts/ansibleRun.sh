#!/bin/bash

./openvpn.sh
./setEnv.sh

pushd /opt/volumes/k8s-infra/ansible

case $ANSIBLE_ACTION in
  vm_create)
    ANSIBLE_PLAYBOOK_FILE=playbook/${CLOUD_PROVIDER}_${ANSIBLE_ACTION}_aggregate.yml;
    ANSIBLE_PLAYBOOK_JSON_PARAMETERS=$( jq -cn \
                  --arg vm_name "${VM_NAME}" \
                  --arg vm_flavor "${VM_FLAVOR}" \
                  --arg vm_image "${VM_IMAGE}" \
                  --arg k8s_version "${K8S_VERSION}" \
                  '{vm_name: $vm_name, k8s_type=masters, k8s_version: $k8s_version, openstack: {vm: {network: "provider_net_shared" , flavor: $vm_flavor, image: $vm_image }}}' );
    ANSIBLE_PLAYBOOK_PARAMETERS="-e '";
    ANSIBLE_PLAYBOOK_PARAMETERS+="'";
    ANSIBLE_PLAYBOOK_TAGS+=" --tags create";;
  vm_remove)
    ANSIBLE_PLAYBOOK_FILE=playbook/${CLOUD_PROVIDER}_${ANSIBLE_ACTION}_aggregate.yml;
    ANSIBLE_PLAYBOOK_JSON_PARAMETERS=$( jq -cn \
                  --arg vm_name "${VM_NAME}" \
                  '{vm_name: $vm_name}' );
    ANSIBLE_PLAYBOOK_PARAMETERS="-e '${ANSIBLE_PLAYBOOK_JSON_PARAMETERS}'";;
  k8s_install)
    echo "K8S_INSTALL!!!";;
  *) 
    echo "The select ${ANSIBLE_ACTION} action is not available.";
    echo "Allowed actions are:";
    echo "  vm_create - create a new VM";
    echo "  vm_remove - remove an existing VM";
    echo "  k8s_install - Install k8s";; 
esac

ANSIBLE_COMMAND="ansible-playbook ${ANSIBLE_PLAYBOOK_PARAMETERS} ${ANSIBLE_PLAYBOOK_FILE}"

echo "ANSIBLE_PLAYBOOK_FILE: ${ANSIBLE_PLAYBOOK_FILE}"
echo "ANSIBLE_PLAYBOOK_PARAMETERS: ${ANSIBLE_PLAYBOOK_PARAMETERS}"
echo "Running the following command: ${ANSIBLE_COMMAND}"

# ansible-playbook ${ANSIBLE_PLAYBOOK_PARAMETERS} ${ANSIBLE_PLAYBOOK_FILE}
bash -ic "${ANSIBLE_COMMAND}"
# ansible-playbook -e '{"vm_name":"testcontainer-k121-centos8-test-04"}' playbook/openstack_vm_remove_aggregate.yml
