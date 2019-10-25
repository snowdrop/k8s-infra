# Instructions

- Have tekton operator deployed on k8s/openshift
- Install the following yaml resources to start a JIB build and image push to the docker registry
```bash
kubectl apply -f secret.yml,secret-trustore.yml,task-jib-maven.yml,taskrun-jib-local-registry.yml
```
- Check the log of the pod

To clean, delete the resources
```bash
kubectl delete all,secrets --all
```
