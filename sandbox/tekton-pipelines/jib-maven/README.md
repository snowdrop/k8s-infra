# Instructions

- Have tekton operator deployed on k8s/openshift
- Install the following yaml resources to start a JIB build and image push to the docker registry
```bash
kubectl apply -f resources/
```
- Check the log of the pod to see the build result
```bash
kBProgress (1): 450/480 kBProgress (1): 454/480 kBProgress (1): 458/480 kBProgress (1): 462/480 kBProgress (1): 466/480 kBProgress (1): 470/480 kBProgress (1): 475/480 kBProgress (1): 479/480 kBProgress (1): 480 kB                        Downloaded from central: https://repo.maven.apache.org/maven2/org/apache/commons/commons-lang3/3.5/commons-lang3-3.5.jar  (480 kB at 1.5 MB/s)
[INFO] 
[INFO] Containerizing application to docker-registry.default.svc:5000/cmoullia/spring-boot-jib...
[WARNING] Base image 'gcr.io/distroless/java:8' does not use a specific image digest - build may not be reproducible
[INFO] Retrieving registry credentials for docker-registry.default.svc:5000...
[INFO] Getting manifest for base image gcr.io/distroless/java:8...
[INFO] Building resources layer...
[INFO] Building classes layer...
[INFO] Using base image with digest: sha256:0f237c1419cb5358308a0a6ae048bdd9bb4e5065083e13101af3590f1dec3e20
[INFO] 
[INFO] Container entrypoint set to [java, -cp, /app/resources:/app/classes:/app/libs/*, org.eclipse.che.examples.HelloWorld]
[INFO] 
[INFO] Built and pushed image as docker-registry.default.svc:5000/cmoullia/spring-boot-jib
[INFO] 
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  10.609 s
[INFO] Finished at: 2019-10-25T16:21:49Z
[INFO] ------------------------------------------------------------------------
```
- Then you should be able to see an imagestream
```bash
oc get imagestreams 
NAME              DOCKER REPO                                                 TAGS      UPDATED
spring-boot-jib   docker-registry.default.svc:5000/cmoullia/spring-boot-jib   latest    3 minutes ago
```

- Create a pod using a deployment yml and check the log's message
```bash
kubectl apply -f deployment.yml
pod_name=$(oc get pods -lapp=java-hello-app -o name)
oc logs $pod_name
...
```

TODO: Add step to call the endpoint !!

To clean, delete the resources
```bash
kubectl delete -f resources/
kubectl delete imagestreams/spring-boot-jib
```
