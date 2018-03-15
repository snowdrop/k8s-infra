# Instructions to install OpenShift 

This project details how to provision a vm with OpenShift Origin and to to install the following applications required for a Hands On Lab, local demo, test :

- Nexus, Jenkins, Jaeger
- Ansible Service Broker
- Launcher with customized catalog

Table of Contents
=================

   * [Minishift](#minishift)
      * [Post installation tasks](#post-installation-tasks)
      * [Test Launcher](#test-launcher)
   * [Virtualbox](#virtualbox)
   * [Cloud - Hetzner](#cloud---hetzner)


## Minishift

To provision MiniShift with OpenShift Origin 3.7.1 and install the Ansible Service Broker, then use the 
following bash script `bootstrap_vm.sh <image_cache_bolloean> <ocp_version>`. 

It will create a :

- Minishift vm using xhyve as hypervisor 
- `demo` profile

and will :

- Git clone the minishift `ansible-service-broker` addon for the ansible service broker
- Enable/disable minishift cache
- Install the docker images within the OpenShift registry according to the ocp version defined
- Start Minishift using the experimental features

```bash
cd minishift    
./bootstrap_vm.sh true 3.7.1
```

**NOTE** : The minishift `ansible-service-broker` addon is based on this project `https://github.com/eriknelson/minishift-addons` and branch `asb-updates`

**NOTE** : When the vm has been created, then it can be stopped/started using the commands `minishift stop|start --profile demo`

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

## Virtualbox

TODO

## Cloud - Hetzner

TODO

