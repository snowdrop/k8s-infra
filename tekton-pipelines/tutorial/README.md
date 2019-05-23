# Instructions to play with the tutorial

## Say Hello

```bash
kc apply -f taskEcho.yml -n tutorial
kc apply -f taskRunEcho.yml -n tutorial
kc get taskruns/echo-hello-world-task-run -o yaml -n tutorial
```

## Build project
```bash
kc apply -f taskBuild.yml -n tutorial
kc apply -f pipeline-resources.yml -n tutorial
kc apply -f taskRunBuild.yml -n tutorial
kc get taskruns/build-docker-image-from-git-source-task-run -o yaml -n tutorial
kc delete taskruns/build-docker-image-from-git-source-task-run
```

To see all the resource created so far as part of Tekton Pipelines, run the command:

```bash
kc get tekton-pipelines
```

## Pipeline project
```bash
kc apply -f taskDeployKubectl.yml -n tutorial
kc apply -f pipeline.yml -n tutorial
kc apply -f pipelineRun.yml -n tutorial
kc get pipelineRuns/tutorial-pipeline-run-1 -n tutorial -o yaml
kc delete pipelineRuns/tutorial-pipeline-run-1 -n tutorial
```


