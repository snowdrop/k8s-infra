# Delete cloud server and key
hcloud server delete $VM_NAME
hcloud ssh-key delete snowdrop
hcloud ssh-key create --name snowdrop --public-key-from-file ~/.ssh/id_hetzner_snowdrop.pub

# Create the cloud init file using user private key
$BASH_SCRIPTS_DIR/create-user-data.sh $SALT_TEXT $USER_PASSWORD

# Create cloud instance - centos7
hcloud server create --name $VM_NAME --type $VM_TYPE --image $VM_IMAGE --ssh-key snowdrop --user-data-from-file $BASH_SCRIPTS_DIR/user-data

# Get IP address and wait till we can SSH
IP_HETZNER=$(hcloud server describe $VM_NAME  -o json | jq -r .public_net.ipv4.ip)
ssh-keygen -R $IP_HETZNER
while ! nc -z $IP_HETZNER 22; do echo "Wait till we can ssh to the $VM_NAME vm ..."; sleep 10; done
