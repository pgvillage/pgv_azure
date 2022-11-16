#!/bin/bash
set -e

echo Setup git
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
sudo apt-get update -y && sudo apt-get install git -y
if [ ! -d ~/git/pgv_azure ]; then
  mkdir -p ~/git && cd ~/git && git clone https://github.com/pgvillage/pgv_azure
fi
if [ ! -d ~/git/pgvillage ]; then
  mkdir -p ~/git && cd ~/git && git clone https://github.com/pgvillage/pgvillage && cd pgvillage && ln -s ~/git/pgv_azure/environments
fi
cd

echo Install python3
# For more info, see https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
sudo apt-get install -y python3-pip libffi-dev
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1

echo Install ansible
pip3 install --upgrade --user pip ansible azure-cli-core --upgrade cryptography azure-identity packaging netaddr
~/.local/bin/ansible-galaxy collection install azure.azcollection --force
pip3 install --user -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt

echo Install ansible
pip3 install --upgrade --user chainsmith

echo Setup ssh localhost
[ -f ~/.ssh/id_rsa.pub ] || ssh-keygen -q -f ~/.ssh/id_rsa -P ""
grep -q $USER@$HOSTNAME ~/.ssh/authorized_keys || cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
ssh-keygen -H -F localhost > /dev/null || ssh-keyscan -H localhost >> ~/.ssh/known_hosts
