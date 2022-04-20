#!/bin/bash

echo "Setting the GPG configuration..."
gpgconf --kill gpg-agent
gpg-agent --verbose --daemon --log-file /tmp/gpg-agent.log --allow-preset-passphrase --default-cache-ttl=31536000
echo "${PASS_GPG_KEY_PASSPHRASE}" | /usr/libexec/gpg-preset-passphrase --verbose --preset ${PASS_GPG_KEYGRIP_NAME}

echo "Configuring GIT..."
git config --global user.email "${GIT_EMAIL}"
git config --global user.name "${GIT_USERNAME}"
