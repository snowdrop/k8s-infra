#!/bin/bash

set -e

SALT_TEXT=$1
VM_PASSWORD=$2
SCRIPT_ABSOLUTE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

get_host_timezone(){
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "$(cat /etc/timezone)"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "from time import gmtime, strftime\nprint strftime('%Z', gmtime())" | python
  else # just return UTC since we don't know how to extract the host timezone
     echo "UTC"
  fi
}

echo -e "Creating user-data file at: \n ${SCRIPT_ABSOLUTE_DIR}"
SNOWDROP_SSH_KEY=$(cat ~/.ssh/id_hetzner_snowdrop.pub)
HOST_TIMEZONE=$(get_host_timezone)
USER_PASSWORD_HASHED=$(openssl passwd -1 -salt $SALT_TEXT $VM_PASSWORD)

sed "s|SSH_PUBLIC_KEY|${SNOWDROP_SSH_KEY}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tpl > "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp
sed "s|TIMEZONE|${HOST_TIMEZONE}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp > "${SCRIPT_ABSOLUTE_DIR}"/user-data
sed "s|USER_PASSWORD_HASHED|${USER_PASSWORD_HASHED}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp > "${SCRIPT_ABSOLUTE_DIR}"/user-data
rm "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp
