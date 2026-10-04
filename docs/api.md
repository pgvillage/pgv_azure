# API documentation: `azure` role

The `azure` role (in [roles/azure](../roles/azure)) creates all the Azure resources a pgVillage cluster needs:

1. A resource group (`tasks/rg.yml`)
2. A storage account and blob container for wal-g backups (`tasks/bucket.yml`)
3. A virtual network, subnet, public IP (VIP), network security group and load balancer (`tasks/nw.yml`)
4. A bastion VM and a VM scaleset running the PostgreSQL servers (`tasks/vmss.yml`)

The role runs on `localhost` (the Ansible control node) through [create_resources.yml](../create_resources.yml).
[clean_resources.yml](../clean_resources.yml) removes the resources again.

All variables are defined in [roles/azure/defaults/main.yml](../roles/azure/defaults/main.yml) and can be
overridden in the inventory, for example in `environments/<cluster>/group_vars/all/azure.yml`.

## Required variables

These variables have no default and must be set in the inventory.

| Variable | Used by | Description |
|---|---|---|
| `azure_control_ip` | role (`nw.yml`) | Public IP address of the Ansible control node. The network security group only allows ssh (port 22) from this address (as a `/32`). |
| `azure_allow_clean` | `clean_resources.yml` | When `true`, the resource group is deleted even if it is not empty, and the generated `group_vars/all/certs.yml` is removed from the inventory. |

## Generic

| Variable | Default | Description |
|---|---|---|
| `azure_cluster_name` | `cluster1` | Name of the cluster. Used as a building block for the names of most Azure resources. |
| `azure_cluster_unique_name` | `{{ azure_cluster_name }}{{ ansible_machine_id \| truncate(10, true, '') }}` | Cluster name suffixed with the first 10 characters of the `ansible_machine_id` of the control node. Used for resources that must be unique (storage account and public DNS name). Changes across control nodes, so hardcode it (or the derived names) for production. |
| `azure_resource_group` | `rg_{{ azure_cluster_name }}` | Resource group that holds all Azure resources of the cluster. `clean_resources.yml` also removes it. |
| `azure_location` | `westeurope` | Azure region where all resources are created. |

## Bastion host

The bastion is a jump host for ssh access to the scaleset VMs. The role writes `group_vars/_postgres/proxy.yml`
to the inventory so Ansible connects to the database servers through the bastion.

| Variable | Default | Description |
|---|---|---|
| `azure_bastion_name` | `bastion{{ azure_cluster_name }}` | Name of the bastion VM. |
| `azure_bastion_vm_size` | `Standard_B1ls` | Azure VM size of the bastion VM. |
| `azure_bastion_image` | `{{ azure_vmss_image }}` | Marketplace image of the bastion VM (dict with `offer`, `publisher`, `sku` and `version`). Defaults to the scaleset image. |
| `azure_bastion_plan` | `{{ azure_vmss_plan }}` | Marketplace plan of the bastion VM (dict with `name`, `publisher` and `product`). Defaults to the scaleset plan. Set to `{}` for images that don't require a plan. Image terms are only accepted for a non-empty plan. |

## VM scaleset

The scaleset holds the PostgreSQL database servers. Each VM gets two data disks: lun 0 for data and lun 1 for WAL.

| Variable | Default | Description |
|---|---|---|
| `azure_vmss_name` | `vmss{{ cluster_name }}` | Name of the VM scaleset. **Note:** this uses the inventory variable `cluster_name`, not `azure_cluster_name`. |
| `azure_vmss_vm_size` | `Standard_DS1_v2` | Azure VM size of the scaleset VMs. |
| `azure_vmss_vm_count` | `'3'` | Number of VMs in the scaleset. |
| `azure_vmss_image` | see below | Marketplace image of the scaleset VMs (dict with `offer`, `publisher`, `sku` and `version`). Use `az vm image list --all --publisher <publisher> --output table` to find values. |
| `azure_vmss_plan` | see below | Marketplace plan of the scaleset VMs (dict with `name`, `publisher` and `product`). Set to `null` for images without a plan. You might have to accept the image terms first with `az vm image terms accept`. |

Defaults for the image and plan (Rocky Linux 9):

```yaml
azure_vmss_image:
  offer: rockylinux-x86_64
  publisher: resf
  sku: 9-base
  version: 9.6.20250531
azure_vmss_plan:
  name: 9-base
  publisher: resf
  product: rockylinux-x86_64
```

## Networking

The network has a `10.0.0.0/16` virtual network with a `10.0.1.0/24` subnet. A load balancer with a static public IP
(VIP) sits in front of the scaleset and forwards these ports:

| Frontend port | Backend port | Purpose |
|---|---|---|
| 22 | 22 | ssh |
| 5432 | 25432 | PostgreSQL (read/write) |
| 5433 | 5432 | PostgreSQL (read only) |

The role writes the VIP address and FQDN to `group_vars/all/azure_vip.yml` in the inventory.

| Variable | Default | Description |
|---|---|---|
| `azure_lb_name` | `lb_{{ azure_cluster_name }}` | Name of the load balancer in front of the scaleset. |
| `azure_lbfe_name` | `lbfe_{{ azure_cluster_name }}` | Name of the frontend IP configuration of the load balancer. |
| `azure_lbbe_name` | `lbbe_{{ azure_cluster_name }}` | Name of the backend address pool of the load balancer. |
| `azure_nw_name` | `nw_{{ azure_cluster_name }}` | Name of the virtual network. |
| `azure_subnet_name` | `sn_{{ azure_cluster_name }}` | Name of the subnet within the virtual network. |
| `azure_vip_name` | `vip_{{ azure_cluster_name }}` | Name of the static public IP address (VIP) attached to the load balancer frontend. |
| `azure_vip_dns_name` | `{{ azure_cluster_unique_name }}` | DNS label of the public IP address. Must be unique within the Azure region. |
| `azure_vip_dns_fqdn` | `{{ azure_vip_dns_name }}.{{ azure_location }}.cloudapp.azure.com` | Fully qualified domain name of the public IP address. |
| `azure_sg_name` | `sg_{{ azure_cluster_name }}` | Name of the network security group. It allows ssh from `azure_control_ip` and PostgreSQL on ports 5432 and 5433. |

## Disks

| Variable | Default | Description |
|---|---|---|
| `azure_data_gb` | `100` | Size (in GB) of the data disk (lun 0) of each scaleset VM. |
| `azure_wal_gb` | `10` | Size (in GB) of the WAL disk (lun 1) of each scaleset VM. |
| `azure_vm_disk_type` | `Standard_LRS` | Managed disk type of the OS disks (for example `Standard_LRS`, `StandardSSD_LRS` or `Premium_LRS`). |
| `azure_data_disk_type` | `{{ azure_vm_disk_type }}` | Managed disk type of the data disks. |
| `azure_wal_disk_type` | `{{ azure_data_disk_type }}` | Managed disk type of the WAL disks. |

## Backup storage

wal-g uses this storage for backups. The role writes the storage account name and its access key to
`group_vars/_postgres/wal-g.yml` in the inventory.

| Variable | Default | Description |
|---|---|---|
| `azure_storage_account_name` | `sa{{ azure_cluster_unique_name }}` | Name of the storage account. Must be unique across all of Azure (3-24 lowercase letters and digits). The default is derived from the control node's machine id. That works for demos, but **set a fixed, unique value for production**. |
| `azure_storage_account_type` | `Standard_RAGRS` | Replication type of the storage account (for example `Standard_LRS`, `Standard_GRS` or `Standard_RAGRS`). |
| `azure_storage_container` | `backup{{ azure_cluster_name }}` | Name of the blob container in the storage account that holds the backups. |

## Generated inventory files

The role writes these files to the inventory so the pgVillage playbooks can use them:

| File | Contents |
|---|---|
| `group_vars/all/azure_vip.yml` | `azure_vip_ip`, `azure_vip_dns_fqdn` |
| `group_vars/_postgres/wal-g.yml` | `azure_backup_access_key`, `azure_storage_account_name` |
| `group_vars/_postgres/proxy.yml` | `ansible_ssh_common_args` (ssh through the bastion) |

## Example

```yaml
# environments/mycluster/group_vars/all/azure.yml
---
azure_control_ip: 40.113.107.40
azure_cluster_name: "{{ cluster_name }}"
azure_allow_clean: true
azure_storage_account_name: samyclusterprod01
azure_vmss_vm_count: '3'
azure_vmss_vm_size: Standard_D2s_v5
```
