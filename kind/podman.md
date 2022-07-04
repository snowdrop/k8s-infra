# Podman on macos

- Prereq: install podman > 3.4.2 using `brew install podman`
- Init a new vm
```
podman machine init macvm
Extracting compressed file
```

- Start/stop/delete the VM
```
podman machine stop macvm
podman machine start macvm
INFO[0000] waiting for clients...
INFO[0000] listening tcp://0.0.0.0:7777
INFO[0000] new connection from  to /var/folders/t2/jwchtqkn5y76hrfrws7dqtqm0000gn/T/podman/qemu_macvm.sock
...
podman machine rm macvm
```

# How to create a kind cluster

Prereq: https://kind.sigs.k8s.io/docs/user/rootless/#host-requirements

- Setup the following config files (see prereq)
  ```
  podman machine ssh macvm "sudo mkdir -p /etc/modules-load.d && echo -e \"ip6_tables\nip6table_nat\nip_tables\niptable_nat\" | sudo tee /etc/modules-load.d/iptables.conf > /dev/null"
  
  podman machine ssh macvm "sudo mkdir -p /etc/systemd/system/user@.service.d && echo -e \"[Service]\nDelegate=yes\" | sudo tee /etc/systemd/system/user@.service.d/delegate.conf > /dev/null"
  ```
- Restart the VM
  ```  
  podman machine stop macvm && podman machine start macvm
  ```
- Create/delete the cluster
  ```
  KIND_EXPERIMENTAL_PROVIDER=podman kind delete cluster
  KIND_EXPERIMENTAL_PROVIDER=podman kind create cluster
  ```
- Get the k8s cluster port exposed by the container running withn the VM
  ```
  CLUSTER_NAME="kind-kind"
  K8S_PORT=$(kubectl config view -o json | jq '.clusters[] | select(.name=="'$CLUSTER_NAME'").cluster.server' | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g')
  echo "K8s cluster port: $K8S_PORT"
  ```
- Find the vm port
  ```
  VM_PORT=$(podman system connection ls --format=json | jq '.[] | select(.Name=="macvm*").URI' | sed -e 's,^.*:,:,g' -e 's,.*:\([0-9]*\).*,\1,g')
  echo "Podman VM ssh port: $VM_PORT"
  ```
- Forward it to the podman VM
  ```
  ssh -i $HOME/.ssh/macvm ssh://root@localhost:$VM_PORT -f -N -L ${K8S_PORT}:localhost:${K8S_PORT}
  ```
- Access the k8s cluster
  ```
  kubectl get nodes
  NAME                 STATUS   ROLES                  AGE    VERSION
  kind-control-plane   Ready    control-plane,master   7m2s   v1.21.1
  ```
## Useful commands

- Get the list of the connections
```
podman system connection list
Name        Identity                    URI
macvm*      /Users/cmoullia/.ssh/macvm  ssh://core@localhost:63893/run/user/1000/podman/podman.sock
macvm-root  /Users/cmoullia/.ssh/macvm  ssh://root@localhost:63893/run/podman/podman.sock
```

- Check content of the files created
```
ls -la /Users/cmoullia/.config/containers/podman/machine/qemu/
ls -la /Users/cmoullia/.local/share/containers/podman/machine/qemu
cat /Users/cmoullia/.config/containers/containers.conf
cat /Users/cmoullia/.config/containers/podman/machine/qemu/macvm.ign
cat /Users/cmoullia/.config/containers/podman/machine/qemu/macvm.json
```
