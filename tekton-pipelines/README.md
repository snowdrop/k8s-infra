# Tekton pipelines

First, install Tekton pipelines CRDs and Operator on the cluster

```bash
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
