#!/bin/bash
set -e

echo Setup git
ssh-keyscan -H github.com >> ~/.ssh/known_hosts
sudo apt-get update -y && sudo apt-get install git -y
mkdir git && cd git && git clone https://github.com/pgvillage/pgv_azure && cd


echo Install ansible
# For more info, see https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html
sudo apt-get install -y python3-pip libffi-dev
pip3 install --upgrade --user pip ansible azure-cli-core --upgrade cryptography azure-identity
ansible-galaxy collection install azure.azcollection
pip3 install --user -r ~/.ansible/collections/ansible_collections/azure/azcollection/requirements-azure.txt
