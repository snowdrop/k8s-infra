# Procedure to use k8s cert-manager & let's encrypt

- Blog article : https://www.nearform.com/blog/how-to-run-a-public-docker-registry-in-kubernetes/
- Cert-manager project: https://docs.cert-manager.io/

## LetsEncrypt Tool

Install the following tool in order to communicate with Lets'encrypt
```bash
brew install certbot
``` 

## How to install k8s cert-manager

```bash
oc new-project cert-manager
oc label namespace cert-manager certmanager.k8s.io/disable-validation=true

oc apply -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.6.2/deploy/manifests/00-crds.yaml --validate=false
oc apply -f https://raw.githubusercontent.com/jetstack/cert-manager/v0.6.2/deploy/manifests/cert-manager.yaml --validate=false
```

- Grant `cluster admin` role to the `cert-manager` SA
```bash
oc adm policy add-cluster-role-to-user cluster-admin -z cert-manager -n cert-manager
```

## Getting a TLS certificate using Let's encrypt staging

- Create an `issuer CRD` for `letsencrypt` which represents the CA authority able to generate a certificate
```
oc apply -f http01/letsencrypt-staging.yml
```

**Remark**: The previous command will generate a Private Key Secret which is referenced by the secret `snowdrop-issuert-key`

- Verify what has been created
```bash
oc describe issuer.certmanager.k8s.io/letsencrypt-issuer
Name:         letsencrypt-issuer
Namespace:    cert-manager
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Issuer","metadata":{"annotations":{},"name":"letsencrypt-issuer","namespace":"cert-manager"},"spec"...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Issuer
Metadata:
  Creation Timestamp:  2019-03-06T16:47:08Z
  Generation:          1
  Resource Version:    18944555
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/cert-manager/issuers/letsencrypt-issuer
  UID:                 7ad67f3f-402f-11e9-bce0-107b44b03540
Spec:
  Acme:
    Email:  cmoulliard@redhat.com
    Http 01:
    Private Key Secret Ref:
      Key:   
      Name:  snowdrop-issuer-key
    Server:  https://acme-staging-v02.api.letsencrypt.org/directory
Status:
  Acme:
    Uri:  https://acme-staging-v02.api.letsencrypt.org/acme/acct/8467053
  Conditions:
    Last Transition Time:  2019-03-06T16:47:08Z
    Message:               The ACME account was registered with the ACME server
    Reason:                ACMEAccountRegistered
    Status:                True
    Type:                  Ready
Events:                    <none>
```

- Next, send a `Certificate` request to `letscrypt` using this `Certificate CRD`

```bash
oc apply -f http01/certificate.yml
```

- Verify what has been created
```bash
oc describe certificate.certmanager.k8s.io/snowdrop-me
Name:         snowdrop-me
Namespace:    cert-manager
Labels:       <none>
Annotations:  kubectl.kubernetes.io/last-applied-configuration={"apiVersion":"certmanager.k8s.io/v1alpha1","kind":"Certificate","metadata":{"annotations":{},"name":"snowdrop-me","namespace":"cert-manager"},"spec":{...
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Certificate
Metadata:
  Creation Timestamp:  2019-03-06T16:49:16Z
  Generation:          1
  Resource Version:    18944873
  Self Link:           /apis/certmanager.k8s.io/v1alpha1/namespaces/cert-manager/certificates/snowdrop-me
  UID:                 c74ddab5-402f-11e9-bce0-107b44b03540
Spec:
  Acme:
    Config:
      Domains:
        snowdrop.me
        www.snowdrop.me
      Http 01:
        Ingress:        
        Ingress Class:  nginx
  Common Name:          snowdrop.me
  Dns Names:
    snowdrop.me
    www.snowdrop.me
  Issuer Ref:
    Name:       letsencrypt-issuer
  Secret Name:  snowdrop-me-tls
Status:
  Conditions:
    Last Transition Time:  2019-03-06T16:49:16Z
    Message:               Certificate does not exist
    Reason:                NotFound
    Status:                False
    Type:                  Ready
Events:
  Type    Reason        Age   From          Message
  ----    ------        ----  ----          -------
  Normal  Generated     9s    cert-manager  Generated new private key
  Normal  OrderCreated  9s    cert-manager  Created Order resource "snowdrop-me-593892605"
```

- We will see now if the order has been created
```bash
oc describe order/snowdrop-me-593892605
Name:         snowdrop-me-593892605
Namespace:    cert-manager
Labels:       acme.cert-manager.io/certificate-name=snowdrop-me
Annotations:  <none>
API Version:  certmanager.k8s.io/v1alpha1
Kind:         Order
Metadata:
  Creation Timestamp:  2019-03-06T16:49:16Z
  Generation:          1
  Owner References:
    API Version:           certmanager.k8s.io/v1alpha1
    Block Owner Deletion:  true
    Controller:            true
    Kind:                  Certificate
    Name:                  snowdrop-me
    UID:                   c74ddab5-402f-11e9-bce0-107b44b03540
  Resource Version:        18944878
  Self Link:               /apis/certmanager.k8s.io/v1alpha1/namespaces/cert-manager/orders/snowdrop-me-593892605
  UID:                     c7761023-402f-11e9-bce0-107b44b03540
Spec:
  Common Name:  snowdrop.me
  Config:
    Domains:
      snowdrop.me
      www.snowdrop.me
    Http 01:
      Ingress:        
      Ingress Class:  nginx
  Csr:                MIICrDCCAZQCAQAwLTEVMBMGA1UEChMMY2VydC1tYW5hZ2VyMRQwEgYDVQQDEwtzbm93ZHJvcC5tZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAKZO2DFH7mCLxmm1+rts5laIeGkA9Dg9kFrfkJ8Wl1IEZngA3Gc/bH8rQTuBtvn2ZrWLp7ewfpl3qiO1kiF/rIbm4raaU91SYTpWDrMgXu1kvz/5gyjAwWjL+ms2MNah0/fedZKJNrM760Xq4xvw/917GPMW1nCyk/BOQGD9HkTYtsVscN93kzrDgpCmJCDKZkz5ubHrMO3JM/QYJgyFckDUXCClj64cy3htTE1qF5is0Em7sSrnOpReUbRG6kHLnE48NC3xKS1BRGvUULVaEPopHAZYGA8q5oCAeTuGVB1j8gRDeqimdc1Cd84J0NyNq63VWIQtxu7YMBkECRrZz2kCAwEAAaA6MDgGCSqGSIb3DQEJDjErMCkwJwYDVR0RBCAwHoILc25vd2Ryb3AubWWCD3d3dy5zbm93ZHJvcC5tZTANBgkqhkiG9w0BAQsFAAOCAQEAWx2bMlJ4/MODiHhudrWxRYgKOJN9kzzi2me2Pvw2bFX3Oz2OYHi7DZLvYKaEaxkc/voUBDV8egJexlGeLvFqaRRVJmJ5gz3a9XPFn1wy36q6CJeGFHHPXkQKHRsbEujfOB1b7IPoTcYtQzEQNtTEgdWC6hgd7XNmmwhxeUbhGzFqLT0LN39EXBzy+/BiUu+YXaS4GWlvSb26Pj28Gacj/bqZ7/9NrJtz7W56tclKSYrJL4nchqbS2hzoRQMvWbStBIV0e9cvwgTeb1gdXbjL0bU6Ecl14ZIAt0HST/xeq3Wx3n2a4qAO41IMuRwNXGmdziERrIOHPxn/+voZcHfIBA==
  Dns Names:
    snowdrop.me
    www.snowdrop.me
  Issuer Ref:
    Name:  letsencrypt-issuer
Status:
  Certificate:  <nil>
  Challenges:
    Authz URL:  https://acme-staging-v02.api.letsencrypt.org/acme/authz/PwfeomKelHPeK7QwyLYOmb_wF2bqn50rd6VRQDS-u_s
    Config:
      Http 01:
        Ingress:        
        Ingress Class:  nginx
    Dns Name:           snowdrop.me
    Issuer Ref:
      Name:     letsencrypt-issuer
    Key:        EgVNaxRAAP_F-GLNfGHAUqA4bnfwTw2QdbZ4L6pHcGo.lnZIc09JepuXAg_lzElR-60rYKHwoAUuqna24O74OI0
    Token:      EgVNaxRAAP_F-GLNfGHAUqA4bnfwTw2QdbZ4L6pHcGo
    Type:       http-01
    URL:        https://acme-staging-v02.api.letsencrypt.org/acme/challenge/PwfeomKelHPeK7QwyLYOmb_wF2bqn50rd6VRQDS-u_s/262900554
    Wildcard:   false
    Authz URL:  https://acme-staging-v02.api.letsencrypt.org/acme/authz/9o4FT5P6UrGpSbvxEkYPoQn_Ka6Qb7fw-iQ14Ly07ZA
    Config:
      Http 01:
        Ingress:        
        Ingress Class:  nginx
    Dns Name:           www.snowdrop.me
    Issuer Ref:
      Name:      letsencrypt-issuer
    Key:         4pi6dfrmu-PTdbCl9R5XN9_-rE3GjQ8cZKHUYGg_TAA.lnZIc09JepuXAg_lzElR-60rYKHwoAUuqna24O74OI0
    Token:       4pi6dfrmu-PTdbCl9R5XN9_-rE3GjQ8cZKHUYGg_TAA
    Type:        http-01
    URL:         https://acme-staging-v02.api.letsencrypt.org/acme/challenge/9o4FT5P6UrGpSbvxEkYPoQn_Ka6Qb7fw-iQ14Ly07ZA/262900556
    Wildcard:    false
  Finalize URL:  https://acme-staging-v02.api.letsencrypt.org/acme/finalize/8467053/25552951
  Reason:        
  State:         pending
  URL:           https://acme-staging-v02.api.letsencrypt.org/acme/order/8467053/25552951
Events:
  Type    Reason   Age   From          Message
  ----    ------   ----  ----          -------
  Normal  Created  1m    cert-manager  Created Challenge resource "snowdrop-me-593892605-1" for domain "www.snowdrop.me"
  Normal  Created  1m    cert-manager  Created Challenge resource "snowdrop-me-593892605-0" for domain "snowdrop.me"
```

- You can then go on to run `oc describe challenge snowdrop-me-593892605-0` to further debug the progress of the Order.

## Register a TXT Record needed to use ACME DNS

Trick : https://serverfault.com/questions/750902/how-to-use-lets-encrypt-dns-challenge-validation

- First issue a certbot command to get the TXR record using this manual command
```bash
sudo certbot -d www.snowdrop.me --manual --preferred-challenges dns certonly
Saving debug log to /var/log/letsencrypt/letsencrypt.log
Plugins selected: Authenticator manual, Installer None
Obtaining a new certificate
Performing the following challenges:
dns-01 challenge for www.snowdrop.me

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
NOTE: The IP of this machine will be publicly logged as having requested this
certificate. If you're running certbot in manual mode on a machine that is not
your server, please ensure you're okay with that.

Are you OK with your IP being logged?
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
(Y)es/(N)o: Y

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Please deploy a DNS TXT record under the name
_acme-challenge.www.snowdrop.me with the following value:

xpoFlS36qRFLjO01mBnKRBn9ZRCT9LUbiEOJVXfgv6Y

Before continuing, verify the record is deployed.
- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
Press Enter to Continue
Waiting for verification...
Cleaning up challenges
Failed authorization procedure. www.snowdrop.me (dns-01): urn:ietf:params:acme:error:dns :: DNS problem: NXDOMAIN looking up TXT for _acme-challenge.www.snowdrop.me

IMPORTANT NOTES:
 - The following errors were reported by the server:

   Domain: www.snowdrop.me
   Type:   None
   Detail: DNS problem: NXDOMAIN looking up TXT for
   _acme-challenge.www.snowdrop.me
```

- Or using the command where questions are already answered
```bash
sudo certbot --text --agree-tos --email cmoulliard@redhat.com -d www.snowdrop.me --manual --preferred-challenges dns --expand --renew-by-default  --manual-public-ip-logging-ok certonly
```

## Godaddy

https://tryingtobeawesome.com/encryptdaddy/

