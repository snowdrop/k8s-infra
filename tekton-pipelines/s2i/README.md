# Sample QR app for Knative

## Prepare the project

```bash
oc new-project pipeline-demo

oc create serviceaccount pipeline
oc adm policy add-scc-to-user privileged -z pipeline
oc adm policy add-role-to-user edit -z pipeline
```

## Build pipeline

```bash
oc create -f tasks
oc create -f pipelines/resources.yml
oc create -f pipelines/build-pipeline.yml
oc create -f pipelines/build-pipeline-run.yml
```

## Deploy pipeline

```bash
oc create -f tasks
oc create -f pipelines/resources.yml
oc create -f pipelines/deploy-pipeline.yml
oc create -f pipelines/deploy-pipeline-run.yml
```
