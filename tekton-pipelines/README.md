# Tekton pipelines

First, install Tekton pipelines CRDs and Operator on the cluster

```bash
export KUBECONFIG=remote-k8s.cfg
kubectl apply --filename https://storage.googleapis.com/tekton-releases/latest/release.yaml
```

Next, create `task`, `taskRun` and `Pipeline` yaml resources to say `Hello`

```bash
kubectl apply -f hello/task-hello.yml
kubectl apply -f hello/taskrun-say-hello.yml
```

To see the output of the `TaskRun`, use the following command:
```bash
kubectl get taskruns/echo-hello-world-task-run -o yaml
```

## JIB Maven

Install the resources : git repo and target image reference

```bash
kubectl apply -f jib/git-resource.yml
kubectl apply -f jib/docker-image-resource.yml
kubectl apply -f jib/jib-task.yml
```

Next start the build

```bash
kubectl apply -f jib/build-task-run.yml
```

To clean

```bash
kubectl delete -f jib/build-task-run.yml
kubectl delete -f jib/git-resource.yml
kubectl delete -f jib/docker-image-resource.yml
```

Follow what is happening

```bash
kubectl get taskrun.tekton.dev/example-jib-maven -o yaml
```



