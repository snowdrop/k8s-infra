## Tekton S2I JDK8

First, install Tekton pipelines CRDs and Operator on the k8s cluster

```bash
export KUBECONFIG=remote-k8s.cfg
kubectl apply --filename https://storage.googleapis.com/tekton-releases/latest/release.yaml
```

When the Tekton operator is ready, then perform the following steps

Create a kubernetes secret of type `kubernetes.io/basic-auth` in order to been authenticated with the `quay.io` registry

```bash
sed -e 's/QUAY_ROBOT_USER/<QUAY_ROBOT_USER>/g' -e 's/QUAY_ROBOT_PWD/<QUAY_ROBOT_PWD>/g' resources/docker-secret.yml.tmpl > resources/docker-secret.yml
```

Create on Quay.io a repository and grant the Robot user account to have write permissions

Install the k8s resources
```bash
kubectl apply -f resources/docker-secret.yml
kubectl apply -f resources/sa.yml
```

Install the s2i jdk8 task

```bash
kubectl apply -f tasks/clone-build.yml
```

Next, execute this task to git clone a SpringBoot repo, build it using s2i tool and openjdk8 s2i image

```bash
kubectl apply -f runtasks/springboot-example.yml
```

Look to the status of the task running
```bash
kc describe taskrun.tekton.dev/s2i-springboot-example 
```

and check the status of the build, push tasks

```bash

```

Clean up
```bash
kc delete taskrun.tekton.dev/s2i-springboot-example
kc delete task.tekton.dev/s2i-jdk8
```
