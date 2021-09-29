#!/usr/bin/env bash

create_openssl_cfg() {
CFG=$(cat <<'EOF'
[req]
distinguished_name = subject
x509_extensions    = x509_ext
prompt             = no

[subject]
C  = BE
ST = Namur
L  = Florennes
O  = Red Hat
OU = Snowdrop
CN = localhost

[x509_ext]
basicConstraints        = critical, CA:TRUE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid:always, issuer:always
keyUsage                = critical, cRLSign, digitalSignature, keyCertSign
nsComment               = "OpenSSL Generated Certificate"
subjectAltName          = @alt_names

[alt_names]
DNS.1 = kind-registry
DNS.2 = localhost
DNS.3 = 127.0.0.1
EOF)

echo "$CFG"
}
