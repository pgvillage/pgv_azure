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
  --set tags.applicationRole=ansible_runner
```
* log into it:
```
ssh azureuser@$(az vm show -d -g pgVillage -n pgVControl --query publicIps -o tsv)
```
* bootstrap it into aPgVillage Ansible Control Node
```
curl https://raw.githubusercontent.com/pgvillage/pgv_azure/main/bootstrap_debian.sh | bash
```
* log in to azure: `az login`

## ALternate
* Create a CentOS VM Ansible Control Node on Azure by following [this](https://docs.microsoft.com/en-us/azure/developer/ansible/install-on-linux-vm?tabs=azure-cli#install-ansible-on-an-azure-linux-virtual-machine).

