#!/bin/bash
set -e

function cluster_exists() {
  if [ ! -d "environments/${CLUSTER}" ]; then
    echo "Cannot deploy. Missing environment $PWD/environments/${CLUSTER}/"
    exit 1
  fi
}


CLUSTER=${1:-cluster1}
cd ~/git/pgv_azure && cluster_exists
time ansible-playbook -i environments/cluster1 create_resources.yml
echo "Sleeping 60 sec. for all scaleset vms to come alive"
sleep 60
time ansible-playbook -i environments/cluster1 inventory.yml

cd ~/git/pgvillage && cluster_exists
time ansible-playbook -i environments/cluster1 functional-all.yml
