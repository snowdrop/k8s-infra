#!/bin/bash

set -e

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
YOUR_SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
HOST_TIMEZONE=$(get_host_timezone)
sed "s|SSH_PUBLIC_KEY|${YOUR_SSH_KEY}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tpl > "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp
sed "s|TIMEZONE|${HOST_TIMEZONE}|g" "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp > "${SCRIPT_ABSOLUTE_DIR}"/user-data
rm "${SCRIPT_ABSOLUTE_DIR}"/user-data.tmp
