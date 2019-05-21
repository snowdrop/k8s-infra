## Tekton S2I JDK8

### Common tasks

First, install `Tekton pipelines CRDs and Controller` on the k8s/openshift cluster

```bash
export KUBECONFIG=remote-k8s.cfg
kubectl apply --filename https://storage.googleapis.com/tekton-releases/latest/release.yaml
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

```

## Clean up
```bash
kubectl delete taskruns --all
kubectl delete tasks --all
kubectl delete secret/basic-user-pass
kubectl delete serviceaccount/build-bot
```
