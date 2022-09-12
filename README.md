# pg Village
Run a 100% Open Source awesome PostgreSQL solution

## TL;DR
To get going on Azure:
* Create an azure VM (this will be the bootstrap host to run Ansible creating the environments):
```
az group create --name pgVillage --location westeurope
az vm create \
  --resource-group pgVillage \
  --name pgVControl \
  --image Debian \
  --admin-username azureuser \
  --generate-ssh-keys \
  --tags applicationRole=ansible_runner
```

P.s. VMSize B1ls seems too small. Running with B1s seems to work good ATM.
* log into it:
```
ssh azureuser@$(az vm show -d -g pgVillage -n pgVControl --query publicIps -o tsv)
```
* bootstrap it into aPgVillage Ansible Control Node
```
curl https://raw.githubusercontent.com/pgvillage/pgv_azure/main/bootstrap_debian.sh | bash
```
* log in to azure: `az login` or alternatively create a credentials file in ~/.azure/credentials with the required settings (subscription_id, client_id, secret, tenant). Example:
```
cat ~/.azure/credentials
[default]
subscription_id=abcd1234-98fe-1a2b-f9e8-567cde123abc
client_id=12ab34cd-56ef-78ab-90cd-1a2b3c4d5e6e
secret=fK~8Q~anySecretAppliesHere~WhatEverWorks
tenant=cdef7890-a4b5-5a5b-6b6c-9876543fedcb
```
* Run Ansible-playbook:
```
cd ~/git/pgv_azure/
~/.local/bin/ansible-playbook -i environments/cluster1 create_vms.yml
```
## Alternate
* Create a CentOS VM Ansible Control Node on Azure by following [this](https://docs.microsoft.com/en-us/azure/developer/ansible/install-on-linux-vm?tabs=azure-cli#install-ansible-on-an-azure-linux-virtual-machine).

