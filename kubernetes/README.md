# Installation of k8s 


Required variables:

| Variable | Rec. Location | Comments |
| --- | --- | --- |
| k8s_version | host_vars | Version of k8s to be installed |

```bash
$ ansible-playbook kubernetes/ansible/k8s.yml --limit k8s-116
```
