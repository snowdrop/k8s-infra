# Modify Docker config

- Add insecure registries which is required by OpenShift cluster

```bash
cat << EOF > /etc/docker/daemon.json
{
  "insecure-registries" : [ "172.30.0.0/16" ]
 }
EOF

systemctl daemon-reload
systemctl enable docker
systemctl restart docker
```

# Install OCP cluster on vm using `oc cluaster up`

- Interesting links :
  - https://github.com/openshift/origin/blob/master/docs/cluster_up_down.md
  - https://stefanopicozzi.blog/2016/12/18/getting-started-with-oc-cluster-updown/

# With 3.9, we can't enable service-catlog option
# -- Registering template service broker with service catalog ... FAIL
#  Error: cannot register the template service broker
#  Caused By:
#    Error: cannot process template openshift-infra/template-service-broker-registration
#    Caused By:
#      Error: error processing template "openshift-infra/template-service-broker-registration": namespaces "openshift-template-service-broker" not found


```bash
yum install -y wget
mkdir -p origin && cd origin
RELEASE="v3.7.0"
VERSION="v3.7.0-7ed6862"
URL="https://github.com/openshift/origin/releases/download/$RELEASE/openshift-origin-server-$VERSION-linux-64bit.tar.gz"
wget -O origin-server-$VERSION-linux-64bit.tar.gz https://github.com/openshift/origin/releases/download/$RELEASE/openshift-origin-server-$VERSION-linux-64bit.tar.gz
tar -vxf origin-server-$VERSION-linux-64bit.tar.gz
mv openshift-origin-server-$VERSION-linux-64bit openshift-$RELEASE
cd openshift-$RELEASE/

cp oc /usr/local/bin
cp kubectl /usr/local/bin
ln -s /var/lib/openshift/config/ /etc/origin

export PATH="$(pwd)":$PATH
```

- Register OpenShift as a service

```bash
cat > /etc/systemd/system/openshift.service << 'EOF'
[Unit]
Description=OpenShift oc cluster up Service
After=docker.service
Requires=docker.service

[Service]
ExecStart=/usr/local/bin/oc cluster up --host-config-dir=/var/lib/openshift/config --host-data-dir=/var/lib/openshift/data --host-pv-dir=/tmp --host-volumes-dir=/var/lib/openshift/volumes --use-existing-config=true --public-hostname=192.168.99.50 --routing-suffix=192.168.99.50.nip.io --loglevel=1
ExecStop=/usr/local/bin/oc cluster down
WorkingDirectory=/var/lib/openshift
Restart=no
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=occlusterup
User=root
Type=oneshot
RemainAfterExit=yes
TimeoutSec=300

[Install]
WantedBy=multi-user.target
EOF

mkdir -p /var/lib/openshift/{config,pv,data,volumes}
ln -s /var/lib/openshift/config/ /etc/origin
systemctl enable openshift.service
systemctl start openshift.service
```

- Disable `selinux` otherwise we can't install Nexus with persistent storage as we get this error during pod creation `java.io.FileNotFoundException: /sonatype-work/nexus.lock (Permission denied)`
```bash
setenforce 0
```
TODO : We should disable permanently selinux - http://sharadchhetri.com/2013/02/27/how-to-disable-selinux-in-red-hat-or-centos/ !

## Install nexus, jaeger, ...

- Next run the playbook as usual
```bash
ansible-playbook -i inventory/cloud_host playbook/post_installation.yml -e openshift_node=masters 
```

- Process to delete `infra` project could fail during a retry of the command. This bug should be fixed under `3.9`
```bash
TASK [create_projects : Delete Project {{ item }} if it exists] **************************************************************************************************************************************************************************************
failed: [192.168.99.50] (item=infra) => {"changed": true, "cmd": "oc delete project infra --ignore-not-found=true --force --now", "delta": "0:00:00.269344", "end": "2018-03-20 10:48:38.845692", "item": "infra", "msg": "non-zero return code", "rc": 1, "start": "2018-03-20 10:48:38.576348", "stderr": "Error from server (Conflict): Operation cannot be fulfilled on namespaces \"infra\": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system.", "stderr_lines": ["Error from server (Conflict): Operation cannot be fulfilled on namespaces \"infra\": The system is ensuring all content is removed from this namespace.  Upon completion, this namespace will automatically be purged by the system."], "stdout": "", "stdout_lines": []}
```

- Idem for `oc adm policy add-scc-to-user`. See hereafter

```bash
TASK [persistence : Define scc security for the pv-recycler-controller] ******************************************************************************************************************************************************************************
fatal: [192.168.99.50]: FAILED! => {"changed": true, "cmd": "oc adm policy add-scc-to-user hostmount-anyuid system:serviceaccount:openshift-infra:pv-recycler-controller\n oc create -f /tmp/sa-pv-recyler-controller.yml", "delta": "0:00:00.507241", "end": "2018-03-20 10:50:04.263525", "msg": "non-zero return code", "rc": 1, "start": "2018-03-20 10:50:03.756284", "stderr": "Error from server (Forbidden): error when creating \"/tmp/sa-pv-recyler-controller.yml\": serviceaccounts \"pv-recycler-controller\" is forbidden: unable to create new content in namespace infra because it is being terminated.", "stderr_lines": ["Error from server (Forbidden): error when creating \"/tmp/sa-pv-recyler-controller.yml\": serviceaccounts \"pv-recycler-controller\" is forbidden: unable to create new content in namespace infra because it is being terminated."], "stdout": "scc \"hostmount-anyuid\" added to: [\"system:serviceaccount:openshift-infra:pv-recycler-controller\"]", "stdout_lines": ["scc \"hostmount-anyuid\" added to: [\"system:serviceaccount:openshift-infra:pv-recycler-controller\"]"]}
```

# To clean the cluster

```bash
systemctl stop openshift.service
rm -rf /var/lib/openshift/config/
rm -rf /var/lib/openshift/data/member/
systemctl start openshift.service
```