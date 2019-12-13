# How to generate new CA Cert 

Table of Contents
=================

* [How to generate new CA Cert](#how-to-generate-new-ca-cert)
   * [Procedure using Kubernetes CSR](#procedure-using-kubernetes-csr)
      * [cfssl](#cfssl)
      * [openssl](#openssl)
   * [Procedure using : onessl tool](#procedure-using--onessl-tool)
   * [Procedure using : oc adm](#procedure-using--oc-adm)
   * [Procedure to renew kubelet certificate](#procedure-to-renew-kubelet-certificate)
      * [All in one](#all-in-one)

Useful links:

- https://stackoverflow.com/questions/53212149/x509-certificate-signed-by-unknown-authority-kubeadm
- https://kubernetes.io/docs/concepts/cluster-administration/certificates/

## Procedure using Kubernetes CSR

Both approaches tested on ocp 3.11 using a `CertificateSigningRequest` and cluster up are failing as the certificate controller is 
not started at boot time and by consequence, even if the CSR is approved, no certificate will be generated.
See -> https://github.com/kubernetes/minikube/issues/1647

### cfssl

See docker-registry role `ansible/playbook/roles/docker_registry/tasks/generate_server_crt.yml` for an example
or test the code hereafter coming from kubernetes doc: `https://kubernetes.io/docs/tasks/tls/managing-tls-in-a-cluster/#requesting-a-certificate`

```bash
cat <<EOF | cfssl genkey - | cfssljson -bare server
{
  "hosts": [
    "my-svc.my-namespace.svc.cluster.local",
    "my-pod.my-namespace.pod.cluster.local",
    "192.0.2.24",
    "10.0.34.2"
  ],
  "CN": "my-pod.my-namespace.pod.cluster.local",
  "key": {
    "algo": "ecdsa",
    "size": 256
  }
}
EOF

cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1beta1
kind: CertificateSigningRequest
metadata:
  name: my-svc.my-namespace
spec:
  request: $(cat server.csr | base64 | tr -d '\n')
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

kubectl certificate approve my-svc.my-namespace

kubectl get csr my-svc.my-namespace -o jsonpath='{.status.certificate}' \
    | base64 --decode > server.crt
```

### openssl

See the following bash file `kubernetes/gen-cert-csr.sh` for an example using `openssl` and `kubernetes CSR`

## Procedure using : onessl tool

See `ansible/playbook/roles/kubedb/files/kubedb.sh#L458-L470`

```bash
curl -fsSL -o onessl https://github.com/kubepack/onessl/releases/download/v0.14.0/onessl-darwin-amd64
chmod +x onessl
mv onessl /usr/local/bin

onessl create ca-cert --cert-dir pki
onessl create server-cert server --domains=kubedb-operator-kubedb.svc --cert-dir pki
```

## Procedure using : oc adm

- Generate ca certificate chain : `ca.crt` and `ca.key`
```bash
oc adm ca create-signer-cert \
    --key=pki/ca.key \
    --cert=pki/ca.crt \
    --serial=pki/apiserver.serial.txt \
    --name=kubedb-signer
```
- Create certificate and keys for by example the `kubedb` apiserver
```bash
oc adm ca create-server-cert \ 
     --cert='pki/apiserver.crt' \
     --key='pki/apiserver.key' \
     --hostnames='apiserver.kubedb.svc,apiserver.kubedb.svc.cluster.local,apiserver.kubedb' \
     --signer-cert='pki/ca.crt' \
     --signer-key='pki/ca.key' \
     --signer-serial='pki/apiserver.serial.txt'
```

- Then create a secret and mount the `apiserver.crt/key`
TODO
```bash
oc secrets link
```
- Mount it to the `ApiService` of KubeDB

## Procedure to renew kubelet certificate

- Create temp dir
```bash
mkdir ~/mycerts; cd ~/mycerts
```

- Install tools
```bash
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o cfssl
chmod +x cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o cfssljson
chmod +x cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o cfssl-certinfo
chmod +x cfssl-certinfo
```

- Create a JSON config file for generating the `CA` file, for example, `ca-config.json`
```bash
cat <<EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "8760h"
      }
    }
  }
}
EOF
```
- Create a JSON config file for CA certificate signing request (CSR), for example, ca-csr.json.
  Be sure to replace the values marked with angle brackets with real values you want to use.
```bash
cat <<EOF > ca-csr.json
{
    "CN": "kubernetes",
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names":[{
       "C": "BE",
       "ST": "Namur",
       "L": "Florennes",
       "O": "Red Hat",
       "OU": "Snowdrop"
    }]
  }
EOF
```  

- Generate CA key (ca-key.pem) and certificate (ca.pem)
```bash
./cfssl gencert -initca ca-csr.json | ./cfssljson -bare ca
```

- Create a JSON config file for generating keys and certificates for the API server, for example, server-csr.json.
  Be sure to replace the values in angle brackets with real values you want to use.
  The `MASTER_CLUSTER_IP` is the service cluster IP for the API server `kubectl get service/kubernetes -n default -o jsonpath='{.spec.clusterIP}'`.
  The sample below also assumes that you are using cluster.local as the default DNS domain name.
```bash
cat <<EOF > kubelet-csr.json
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "10.96.0.1",
    "88.99.189.131",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "BE",
    "ST": "Namur",
    "L": "Florennes",
    "O": "Red Hat",
    "OU": "Snowdrop"
  }]
}
EOF
```

- Generate the key and certificate for the API server, which are by default saved into file `server-key.pem` and `server.pem` respectively:
```bash
./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem --config=ca-config.json -profile=kubernetes kubelet-csr.json | ./cfssljson -bare kubelet
```

- Copy the files to your nodes:
```bash
cp /var/lib/kubelet/pki/kubelet.crt /var/lib/kubelet/pki/kubelet.crt.bk
cp /var/lib/kubelet/pki/kubelet.key /var/lib/kubelet/pki/kubelet.key.bk
cp kubelet.pem /var/lib/kubelet/pki/kubelet.crt
cp kubelet-key.pem /var/lib/kubelet/pki/kubelet.key
```

Restart the kubelet on your node:
```bash
systemctl restart kubelet
```

### All in one
```bash
mkdir ~/mycerts; cd ~/mycerts

curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o cfssl
chmod +x cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o cfssljson
chmod +x cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o cfssl-certinfo
chmod +x cfssl-certinfo

cat <<EOF > ca-config.json
{
  "signing": {
    "default": {
      "expiry": "8760h"
    },
    "profiles": {
      "kubernetes": {
        "usages": [
          "signing",
          "key encipherment",
          "server auth",
          "client auth"
        ],
        "expiry": "8760h"
      }
    }
  }
}
EOF

cat <<EOF > ca-csr.json
{
    "CN": "kubernetes",
    "key": {
      "algo": "rsa",
      "size": 2048
    },
    "names":[{
       "C": "BE",
       "ST": "Namur",
       "L": "Florennes",
       "O": "Red Hat",
       "OU": "Snowdrop"
    }]
  }
EOF
  
./cfssl gencert -initca ca-csr.json | ./cfssljson -bare ca

! Get MASTER_IP - kubectl get service/kubernetes -n default -o jsonpath='{.spec.clusterIP}

cat <<EOF > kubelet-csr.json
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "10.96.0.1",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names":[{
    "C": "BE",
    "ST": "Namur",
    "L": "Florennes",
    "O": "Red Hat",
    "OU": "Snowdrop"
  }]
}
EOF

./cfssl gencert -ca=ca.pem -ca-key=ca-key.pem --config=ca-config.json -profile=kubernetes kubelet-csr.json | ./cfssljson -bare kubelet

cp /var/lib/kubelet/pki/kubelet.crt /var/lib/kubelet/pki/kubelet.crt.bk
cp /var/lib/kubelet/pki/kubelet.key /var/lib/kubelet/pki/kubelet.key.bk
cp kubelet.pem /var/lib/kubelet/pki/kubelet.crt
cp kubelet-key.pem /var/lib/kubelet/pki/kubelet.key

systemctl restart kubelet
```
