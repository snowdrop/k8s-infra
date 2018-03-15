## cloud vm (Hetzner)

- Secure copy your public key to the vm
```bash
ssh-keygen -R "[127.0.0.1]:5222"
sshpass -f pwd.txt ssh -o StrictHostKeyChecking=no root@127.0.0.1 -p 5222 "mkdir ~/.ssh && chmod 700 ~/.ssh && touch ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
sshpass -f pwd.txt ssh-copy-id -o StrictHostKeyChecking=no -i ~/.ssh/id_rsa.pub root@127.0.0.1 -p 5222
```

- Next, execute tasks as described hereafter

## Local vm (virtualbox)



- Git clone `openshihift-ansible` project using version `3.7`
```bash
git clone -b release-3.7 https://github.com/openshift/openshift-ansible.git
```

- Import RPMs of OpenShift 3.7 as they can't be downloaded by ansible playbook if you don't use CentosAtomic
```bash
ansible-playbook -i inventory playbook/install-package.yaml -e openshift_node=masters
```

Remark : As some rpms packages could not be uploaded correctly during the first execution of the playbook, then re-execute the command !

- Create OpenShift cluster
```bash
ansible-playbook -i inventory openshift-ansible/playbooks/byo/config.yml
```

** NOTES **

- If during the execution of the byo playbook, the service-catloag role reports this error, then relaunch the following playbook
```bash
TASK [ansible_service_broker : Create the Broker resource in the catalog] **************************************************************************************************************************************************************************
fatal: [192.168.99.50]: FAILED! => {"changed": false, "failed": true, "msg": {"cmd": "/usr/bin/oc create -f /tmp/brokerout-dJmL1S -n default", "results": {}, "returncode": 1, "stderr": "error: unable to recognize \"/tmp/brokerout-dJmL1S\": no matches for servicecatalog.k8s.io/, Kind=ClusterServiceBroker\n", "stdout": ""}}

ansible-playbook -i inventory openshift-ansible/playbooks/byo/openshift-cluster/service-catalog.yml
```
- As the `APB` pods could not be deployed correctly, then relaunch the `APB` and `APB etcd` deployments from the console or terminal

- Post installation steps 

  - Enable cluster admin role for `admin` user
  - Setup persistence using `HostPath` mounted volumes `/tmp/pv001 ...`, 
  - Create `infra` project
  - Install Nexus, Jenkins  
  
```bash
ansible-playbook -i inventory playbook/post_installation.yml -e openshift_node=masters
```


## Minishift

### Post installation tasks
 
- Install the fabric8 `launcher` and customize it to use your github account, git repo containing the catalog

```bash
cd minishift
./deploy_launcher_minishift.sh \
    -p my-launcher \
    -i admin:admin \
    -g gitUsername:gitPassword \
    -c https://github.com/snowdrop/cloud-native-catalog.git \
    -b master
```

**NOTE** : Replace the `gitUsername` and `gitPassword` parameters with your `github account` and `git token` in order to let the launcher to create a git repo within your org.

- Install Nexus, Jenkins and Jaeger
```bash
oc login -u admin -p admin
oc new-project infra

oc new-app sonatype/nexus
oc expose svc/nexus
oc set probe dc/nexus \
	--liveness \
	--failure-threshold 3 \
	--initial-delay-seconds 30 \
	-- echo ok
oc set probe dc/nexus \
	--readiness \
	--failure-threshold 3 \
	--initial-delay-seconds 30 \
	--get-url=http://:8081/nexus/content/groups/public
    	

oc adm policy add-scc-to-group anyuid system:authenticated -n infra
oc new-app JENKINS_PASSWORD=admin123 jenkins-persistent -n infra
oc policy add-role-to-user admin system:serviceaccount:infra:jenkins

oc process -f https://raw.githubusercontent.com/jaegertracing/jaeger-openshift/master/all-in-one/jaeger-all-in-one-template.yml | oc create -f -
oc expose service jaeger-collector --port=14268 -n infra  
```

### Test Launcher

Open the `launcher` route hostname

```bash
# LAUNCH_URL="http://$(oc get route/launchpad-nginx -n my-launcher -o jsonpath="{.spec.host}")"
LAUNCH_URL=$(minishift OpenShift service launchpad-nginx -n my-launcher --url)
open $LAUNCH_URL
```