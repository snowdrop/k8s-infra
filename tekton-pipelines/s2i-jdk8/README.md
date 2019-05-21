## S2I JDK8

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

Clean up
```bash
kc delete taskrun.tekton.dev/s2i-springboot-example
kc delete task.tekton.dev/s2i-jdk8
```

## Errors reported

```
Name:         s2i-springboot-example
Namespace:    kube-system
Labels:       tekton.dev/task=s2i-jdk8
Annotations:  kubectl.kubernetes.io/last-applied-configuration:
                {"apiVersion":"tekton.dev/v1alpha1","kind":"TaskRun","metadata":{"annotations":{},"name":"s2i-springboot-example","namespace":"kube-system...
API Version:  tekton.dev/v1alpha1
Kind:         TaskRun
Metadata:
  Creation Timestamp:  2019-05-21T07:22:49Z
  Generation:          1
  Resource Version:    615204
  Self Link:           /apis/tekton.dev/v1alpha1/namespaces/kube-system/taskruns/s2i-springboot-example
  UID:                 3cd0e530-7b99-11e9-8956-fa163e29fc69
Spec:
  Inputs:
    Resources:
      Name:  git-repo
      Resource Ref:
      Resource Spec:
        Params:
          Name:   revision
          Value:  master
          Name:   url
          Value:  https://github.com/snowdrop/rest-http-example
        Type:     git
  Outputs:
    Resources:
      Name:  image
      Resource Ref:
      Resource Spec:
        Params:
          Name:   url
          Value:  quay.io/snowdrop/spring-boot-example
        Type:     image
  Task Ref:
    Kind:  Task
    Name:  s2i-jdk8
  Trigger:
    Type:  
Status:
  Completion Time:  2019-05-21T07:23:33Z
  Conditions:
    Last Transition Time:  2019-05-21T07:23:33Z
    Message:               "build-step-build" exited with code 255 (image: "docker-pullable://kbaig/s2i@sha256:70b5e09f4eac317053ae92be3b1127dbde7eeac3b37a1ff730509086f1e87e73"); for logs run: kubectl -n kube-system logs s2i-springboot-example-pod-e66cf8 -c build-step-build
    Status:                False
    Type:                  Succeeded
  Pod Name:                s2i-springboot-example-pod-e66cf8
  Start Time:              2019-05-21T07:22:49Z
  Steps:
    Name:  build
    Terminated:
      Container ID:  docker://0eed4aaecc006ed7713d49b7512e394f7ed8160d981303aefb4284b0105b24e0
      Exit Code:     255
      Finished At:   2019-05-21T07:23:17Z
      Reason:        Error
      Started At:    2019-05-21T07:23:17Z
    Name:            git-source-git-repo-b7qr2
    Terminated:
      Container ID:  docker://6de7e07082c7b03998adacab0641c010bf01f57959191f3f77dd2f84c5782ef1
      Exit Code:     0
      Finished At:   2019-05-21T07:22:51Z
      Reason:        Completed
      Started At:    2019-05-21T07:22:51Z
    Name:            push
    Terminated:
      Container ID:  docker://eea548553ea426e790de5b87ef951647f5ee854d4def9c1e6d809699018529f9
      Exit Code:     0
      Finished At:   2019-05-21T07:23:33Z
      Reason:        Completed
      Started At:    2019-05-21T07:23:33Z
    Name:            nop
    Terminated:
      Container ID:  docker://4070c0953a61f7181ef2ebe0b0303a0cc656ade6170cdc3ad25fedb80864f580
      Exit Code:     0
      Finished At:   2019-05-21T07:23:33Z
      Reason:        Completed
      Started At:    2019-05-21T07:23:33Z
Events:
  Type     Reason  Age    From                Message
  ----     ------  ----   ----                -------
  Warning  Failed  4m39s  taskrun-controller  "build-step-build" exited with code 255 (image: "docker-pullable://kbaig/s2i@sha256:70b5e09f4eac317053ae92be3b1127dbde7eeac3b37a1ff730509086f1e87e73"); for logs run: kubectl -n kube-system logs s2i-springboot-example-pod-e66cf8 -c build-step-build
```

Pod Log

```bash
kubectl -n kube-system logs s2i-springboot-example-pod-e66cf8 -c build-step-build
F0521 07:23:17.028412 00011 main.go:140] Unable to connect to Docker daemon. Please set the DOCKER_HOST or make sure the Docker socket "unix:///var/run/docker.sock" exists
```
