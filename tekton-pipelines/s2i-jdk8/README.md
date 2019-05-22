## Tekton S2I JDK8

### Common tasks

First, install `Tekton pipelines CRDs and Controller` on the k8s/openshift cluster

```bash
export KUBECONFIG=remote-k8s.cfg
kubectl apply -f https://storage.googleapis.com/tekton-releases/latest/release.yaml
```

When the Tekton controller is ready, then perform the following steps

Create a kubernetes secret of type `kubernetes.io/basic-auth` in order to been authenticated with the `quay.io` registry

```bash
sed -e 's/QUAY_ROBOT_USER/<QUAY_ROBOT_USER>/g' -e 's/QUAY_ROBOT_PWD/<QUAY_ROBOT_PWD>/g' resources/docker-secret.yml.tmpl > resources/docker-secret.yml
```

Create on `Quay.io` a repository and grant the `Robot user account` to have write permissions

### S2i build with docker

Install the k8s resources such as the `serviceaccount` and `secret` created
```bash
kubectl apply -f resources/docker-secret.yml
kubectl apply -f resources/sa-secret.yml
```

Install next the `s2i-jdk8` tekton `task`

```bash
kubectl apply -f tasks/build-push.yml
```

Next, execute this task to git clone a SpringBoot repo as defined using the Git Resource [- see here](https://github.com/snowdrop/openshift-infra/blob/master/tekton-pipelines/s2i-jdk8/tasks/clone-build.yml#L9), build it using s2i tool and openjdk8 s2i image

```bash
kubectl apply -f runtasks/build-push.yml
```

Look to the status of the task running
```bash
kc describe taskrun.tekton.dev/s2i-push-springboot
```

and check the status of the build, push tasks

```bash
kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-s2ibuild
kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8 -c build-step-docker-push
```

### S2i using Buildah

Scenario:
- step 1: git clone 
- step 2: s2i build as dockerfile
- step 3: buildah bud using dockerfile
- step 4: buildah push to quay

Here is a snippet 
```yaml
    - name: step 2 - generate
      image: quay.io/openshift-pipeline/s2i-buildah:latest
      args:
        - ${inputs.params.contextFolder}
        - ${inputs.params.baseImage}
        - ${outputs.resources.image.url}
        -  --image-scripts-url
        - image:///usr/local/s2i
      workingDir: /sources
      volumeMounts:
        - name: generatedsources
          mountPath: /sources
          
    - name: step 3 - build
      image: quay.io/openshift-pipeline/buildah:testing
      command:
        - buildah
      args:
        - bud
        - --layers
        - --tls-verify=${inputs.params.verifyTLS}
        - -f
        - Dockerfile
        - -t
        - ${outputs.resources.image.url}
        - /sources
      volumeMounts:
        - name: libcontainers
          mountPath: /var/lib/containers
        - name: generatedsources
          mountPath: /sources
      securityContext:
        privileged: true

    - name: step 4 - push to quay.io
      image: quay.io/openshift-pipeline/buildah:testing
      command:
        - buildah
      args:
        - push
        - --tls-verify=${inputs.params.verifyTLS}
        - ${outputs.resources.image.url}
      volumeMounts:
        - name: libcontainers
          mountPath: /var/lib/containers
      securityContext:
        privileged: true
```

Deploy the resources on the cluster

```bash
kubectl apply -f resources/docker-secret.yml
kubectl apply -f resources/sa-secret.yml

kubectl apply -f tasks/buildah-push.yml
kubectl apply -f runtasks/buildah-push.yml
```

Look to the status of the task running
```bash
kubectl describe taskrun.tekton.dev/s2i-buildah-push-springboot
```

and check the status of the steps of the build:

```bash
kubectl logs -n kube-system -l tekton.dev/task=s2i-buildah-push -c build-step-generate
kubectl logs -n kube-system -l tekton.dev/task=s2i-buildah-push -c build-step-build
kubectl logs -n kube-system -l tekton.dev/task=s2i-buildah-push -c build-step-push
```

If the build is not yet finished you can watch it
```bash
kubectl logs -n kube-system -l tekton.dev/task=s2i-buildah-push -c build-step-build -f
```

End of the process, you should been able to see that your image has been pushed
```bash
...
Copying config sha256:ce632a123e14d37f484ad8d3c3fe778012cb6e9841113fda602354b61fc2320b
Writing manifest to image destination
Writing manifest to image destination
Storing signatures
Successfully pushed //quay.io/snowdrop/spring-boot-example:latest@sha256:cf99b4a9218c76547d3a7c9eca201776e70c8d1592e3fa17d4167fffce281a49
```

To test the Spring Boot Application using the image created, then install using this list of resources
```bash
kubectl create namespace demo
kubectl apply -f resources/deployment.yaml -n demo
```

and check the log of the pod created
```bash
kubectl logs -l app=spring-boot-rest-http -n demo
Starting the Java application using /opt/jboss/container/java/run/run-java.sh ...
INFO exec  java -javaagent:/opt/jboss/container/jolokia/jolokia.jar=config=/opt/jboss/container/jolokia/etc/jolokia.properties -XX:+UseParallelOldGC -XX:MinHeapFreeRatio=10 -XX:MaxHeapFreeRatio=20 -XX:GCTimeRatio=4 -XX:AdaptiveSizePolicyWeight=90 -XX:MaxMetaspaceSize=100m -XX:+ExitOnOutOfMemoryError -cp "." -jar /deployments/spring-boot-rest-http-2.1.3-2.jar  
OpenJDK 64-Bit Server VM warning: If the number of processors is expected to increase from one, then you should configure the number of parallel GC threads appropriately using -XX:ParallelGCThreads=N
SLF4J: Failed to load class "org.slf4j.impl.StaticLoggerBinder".
SLF4J: Defaulting to no-operation (NOP) logger implementation
SLF4J: See http://www.slf4j.org/codes.html#StaticLoggerBinder for further details.

  .   ____          _            __ _ _
 /\\ / ___'_ __ _ _(_)_ __  __ _ \ \ \ \
( ( )\___ | '_ | '_| | '_ \/ _` | \ \ \ \
 \\/  ___)| |_)| | | | | || (_| |  ) ) ) )
  '  |____| .__|_| |_|_| |_\__, | / / / /
 =========|_|==============|___/=/_/_/_/
 :: Spring Boot ::        (v2.1.3.RELEASE)

I> No access restrictor found, access to any MBean is allowed
Jolokia: Agent started with URL https://10.244.0.65:8778/jolokia/
May 21, 2019 7:39:52 PM org.apache.catalina.core.StandardService startInternal
INFO: Starting service [Tomcat]
May 21, 2019 7:39:52 PM org.apache.catalina.core.StandardEngine startInternal
INFO: Starting Servlet engine: [Apache Tomcat/9.0.16]
May 21, 2019 7:39:52 PM org.apache.catalina.core.AprLifecycleListener lifecycleEvent
INFO: The APR based Apache Tomcat Native library which allows optimal performance in production environments was not found on the java.library.path: [/usr/java/packages/lib/amd64:/usr/lib64:/lib64:/lib:/usr/lib]
May 21, 2019 7:39:52 PM org.apache.catalina.core.ApplicationContext log
INFO: Initializing Spring embedded WebApplicationContext
May 21, 2019 7:40:06 PM org.apache.catalina.core.ApplicationContext log
INFO: Initializing Spring DispatcherServlet 'dispatcherServlet'
```

### OpenShift

Scenario:
- step 1: git clone 
- step 2: s2i build as dockerfile
- step 3: buildah bud using dockerfile
- step 4: buildah push to private local docker registry

**Warning**: Change the `image url` within the file `runtasks/buildah-push-local-registry.yml` in order to use your project's namespace !

Change the SCC of the serviceaccount to give it the `priveleged` role
```bash
echo  Add-on '#{addon-name}' changed the default security context constraints to allow pods to run as any user.
echo  Per default OpenShift runs containers using an arbitrarily assigned user ID.
echo  Refer to https://docs.okd.io/latest/architecture/additional_concepts/authorization.html#security-context-constraints and
echo  https://docs.okd.io/latest/creating_images/guidelines.html#openshift-origin-specific-guidelines for more information.

oc adm policy add-scc-to-group anyuid system:authenticated

#oc apply -f resources/sa.yml
#oc adm policy add-scc-to-user anyuid system:serviceaccount:build-bot:tekton-pipelines-controller
#oc adm policy add-scc-to-user privileged -z build-bot
#oc adm policy add-role-to-user edit -z build-bot
```

Execute the following commands in order to deploy the task and task to be executed (aka taksrun)

```yaml
oc new-project demo
oc apply -f tasks/buildah-push.yml
oc apply -f runtasks/buildah-push-local-registry.yml
```

Verify if the Spring Boot application has been started

**WARNING**: Change the IP address ofthe docker registry `image: 172.30.1.1:5000/demo/spring-boot-example` within the `deployment.yaml` file before to install the resource

```bash
oc new-project demo
oc apply -f resources/deployment.yaml -n demo
```

## Clean up
```bash
kubectl delete taskruns --all
kubectl delete tasks --all
kubectl delete secret/basic-user-pass
kubectl delete serviceaccount/build-bot
```
