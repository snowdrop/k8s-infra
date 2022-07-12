#!/bin/bash

if [[ -v OVPN_HOST ]] && [[ -v OVPN_USER ]] && [[ -v OVPN_PW ]] && [ -d "/opt/volumes/openvpn" ]; then
  touch /etc/openvpn/credentials
  printf '%s\n' "'${OVPN_USER}'" "'${OVPN_PW}'" > /etc/openvpn/credentials
  openvpn --config /opt/volumes/openvpn/vpn.ovpn
fi
