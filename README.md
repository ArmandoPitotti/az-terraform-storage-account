# Overview

This Terraform project contains a template for setting up a Storage Account and Storage Container within a new Vnet (if pre-existent subnet_id is not specified).

## Usage

This module provisions a Storage Account within a Vnet.

```hcl-terraform
module "storage" {
  source                      = "git::ssh://gitlabe2.ext.net.nokia.com/cs/common/iac/az-terraform-storage-account?ref=<version>"
  storage_account_name        = "terraformstates"
  resource_group_name         = var.resource_group_name
  resource_group_location     = var.resource_group_location
  allowed_cidr_blocks         = ["131.228.2.0/27","131.228.32.160/27"]
  storage_account_subnet_id   = var.subnet_id
  storage_container_names     = ["state"]
  storage_data_lake_gen2_name = ""
  key_vault_id                = "id-of-keyvault"
  encryption_key_name         = "name-of-the-encryption-key"
  private_link_enabled        = true
  private_link_subnet         = lookup(module.nokia.subnets, "Zone-High1", null)
}
```

where `<version>` must be changed with the tag version that you want to refer to.

## TODO
- [ ] evaluate vault integration for storage encryption
- [X] list of container names in input
- [ ] do security compliance

## Variables

In `variables.tf` file, the following variables have been defined:

| Name                     | Required | Default                 | Description |
| ----                     | -------- | -------                 | ----------- |
| `resource_group_name`         | Yes | N/A                     | Name of the resource group the Storage Account will be associated to |
| `resource_group_location`     | Yes | westeurope              | Location of the resource group the Storage Account will be associated to |
| `allowed_cidr_blocks`         | Yes | List of Nokia public IP | List of IP or IP ranges in CIDR Format (only public IP) |
| `storage_account_subnet_id`   | No  | ""                      | Pre-existent Subnet ID in which to provision the Storage Account |
| `storage_account_vnet_cidr`   | No* | ["10.0.0.0/16"]         | CIDR list for vnet address space in which the Storage Account is sitting |
| `storage_account_subnet_cidr` | No* | "10.0.1.0/24"           | CIDR for subnet address space in which the Storage Account is sitting  |
| `storage_account_name`        | No  | storage                 | The name of the Storage Account to create |
| `storage_account_full_name`   | No  | ""                      | The storage account name with prefix. Used to override the prefixed storage. |
| `storage_container_names`     | Yes | N/A                     | List of Storage Containers to create) |
| `storage_data_lake_gen2_name` | No  | ""                      | Name of the Data lake Gen 2 File System (if needed) |
| `storage_data_lake_gen2_properties`     | No | {}             | Map of Keys to Base64-Encoded Values which should be assigned to this Data Lake Gen2 File System |
| `private_link_enabled`        | No  | True                   | Enable private link for storage account |
| `private_link_subnet`         | No  | ""                      | Subnet info to supply private link creation |

__*__ used only when storage_account_subnet_id is empty

## Output

This module also defines some useful output variables (listed in `outputs.tf`) that can be highlighted to
the user when Terraform applies and they can be easily queried using the `output` command.

Here all the outputs:

| Name                         | Description |
| ----                         | ----------- |
| `storage_account_id`         | The Storage Account ID |
| `storage_account_access_key` | The Storage Account access key |
| `storage_container_names`    | List of Storage Container names |
| `storage_data_lake_gen2_id`  | List of Data Lake Storage Gen2 ID |
