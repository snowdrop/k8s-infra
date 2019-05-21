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

## Errors

### Build Container log
```bash
kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8  -c build-step-git-source-git-repo-nrrml
{"level":"warn","ts":1558428355.6925228,"logger":"fallback-logger","caller":"logging/config.go:65","msg":"Fetch GitHub commit ID from kodata failed: \"ref: refs/heads/master\" is not a valid GitHub commit ID"}
{"level":"info","ts":1558428356.0517735,"logger":"fallback-logger","caller":"git/git.go:105","msg":"Successfully cloned https://github.com/snowdrop/rest-http-example @ master in path /workspace/git-repo"}

kubectl logs -n kube-system -l tekton.dev/task=s2i-jdk8  -c build-step-build                    
I0521 08:45:56.124218 00013 clone.go:32] Downloading "file:///workspace/git-repo" ...
E0521 08:45:56.132973 00013 git.go:410] Clone failed: source file:///workspace/git-repo, target /tmp/s2i874395392/upload/src,  with output fatal: attempt to fetch/clone from a shallow repository
fatal: Could not read from remote repository.

Please make sure you have the correct access rights
and the repository exists.
E0521 08:45:56.133264 00013 main.go:352] An error occurred: exit status 128

```
