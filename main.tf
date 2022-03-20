locals {
  storage_account_full_name    = var.storage_account_full_name != "" ? var.storage_account_full_name : replace("${replace(lower(var.resource_group_name), "_", "-")}${var.storage_account_name}", "-", "")
  storage_data_lake_gen2_names = var.storage_data_lake_gen2_name == "" ? var.storage_data_lake_gen2_names : [var.storage_data_lake_gen2_name]
  ip_rules                     = [for c in var.allowed_cidr_blocks : replace(c, "//3[12]/", "")] # Storage accounts don't support small CIDR blocks (/31 and /32) https://docs.microsoft.com/en-us/azure/storage/common/storage-network-security#grant-access-from-an-internet-ip-range
  data_readers                 = distinct(concat(var.storage_blob_data_contributors, var.storage_blob_data_readers, var.storage_blob_data_owners))
}

resource "azurerm_storage_account" "storage" {
  name                = local.storage_account_full_name
  resource_group_name = var.resource_group_name
  location            = var.resource_group_location
  # Only use LRS for change account_replication_type. Changing it allows data replication outside region
  # and when data cannot reside outside region we have problems.
  account_replication_type  = "LRS"
  account_tier              = "Standard"
  account_kind              = "StorageV2"
  enable_https_traffic_only = true
  is_hns_enabled            = length(var.storage_data_lake_gen2_names) > 0 ? true : false // is normal storage or data lake

  dynamic "identity" {
    for_each = var.encryption_enabled == true ? [1] : []
    content {
      type = "SystemAssigned"
    }
  }

  blob_properties {
    dynamic "delete_retention_policy" {
      for_each = var.delete_retention_policy_days > 0 ? [1] : []
      content {
        days = var.delete_retention_policy_days
      }
    }
  }

  lifecycle {
    ignore_changes = [
      network_rules[0].virtual_network_subnet_ids, # we want to add networks later and do now want to be overwritten by this
      #account_encryption_source,                   # https://github.com/terraform-providers/terraform-provider-azurerm/pull/2046
    ]
  }

  network_rules {
    default_action = "Deny"         # external
    ip_rules       = local.ip_rules # external
  }

  tags = var.tags
}

resource "null_resource" "storage-lock" {
  # Lock can be create with Terraform also, but Terraform would also destroy the lock on destroy so it will not prevent destroy.
  # Unlock lock manually to destroy the resource
  count = var.prevent_delete ? 1 : 0

  provisioner "local-exec" {
    command = <<EOT
      az lock create --lock-type CanNotDelete --name "${local.storage_account_full_name}-prevent-delete" --resource "${azurerm_storage_account.storage.id}" --notes "Prevent accidental deletion of this important storage account"
    EOT
  }
}

resource "azurerm_advanced_threat_protection" "storage" {
  target_resource_id = azurerm_storage_account.storage.id
  enabled            = true
}

# module "subnets" {
#   source = "git::ssh://git@gitlabe2.ext.net.nokia.com/cs/common/iac/az-terraform-storage-subnet?ref=v0.4.0"
#   #source = "../az-terraform-storage-subnet"

#   subnet_ids           = var.subnet_ids
#   storage_account_name = azurerm_storage_account.storage.name
#   resource_group_name  = azurerm_storage_account.storage.resource_group_name
# }

resource "azurerm_storage_container" "storage" {
  count                 = length(var.storage_container_names)
  name                  = var.storage_container_names[count.index]
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = var.container_access_type
}

resource "azurerm_storage_data_lake_gen2_filesystem" "storage" {
  count              = length(local.storage_data_lake_gen2_names)
  name               = local.storage_data_lake_gen2_names[count.index]
  storage_account_id = azurerm_storage_account.storage.id
  properties         = var.storage_data_lake_gen2_properties
}

resource "azurerm_key_vault_access_policy" "storage" {
  count = var.encryption_enabled == true ? 1 : 0

  key_vault_id = var.key_vault_id

  tenant_id = azurerm_storage_account.storage.identity[0].tenant_id
  object_id = azurerm_storage_account.storage.identity[0].principal_id

  key_permissions = [
    "get",
    "recover",
    "unwrapKey",
    "wrapKey",
  ]
}

resource "null_resource" "encryption-key" {
  count = var.encryption_enabled == true ? 1 : 0

  triggers = {
    encryption_key_name = var.encryption_key_name
    key_vault_id        = var.key_vault_id
    azurerm_storage_id  = azurerm_storage_account.storage.id
  }

  provisioner "local-exec" {
    command = <<EOT
      key_vault_name=$(az keyvault list --query "[?id=='${var.key_vault_id}'] | [0].name" --output tsv)
      key_vault_resource_group=$(az keyvault list --query "[?id=='${var.key_vault_id}'] | [0].resourceGroup" --output tsv)

      key_vault_uri=$(az keyvault show \
        --name $key_vault_name \
        --resource-group $key_vault_resource_group \
        --query properties.vaultUri \
        --output tsv)
      key_version=$(az keyvault key list-versions \
          --name ${var.encryption_key_name} \
          --vault-name $key_vault_name \
          --query [-1].kid \
          --output tsv | cut -d '/' -f 6)
      az storage account update \
          --name ${azurerm_storage_account.storage.name} \
          --resource-group ${azurerm_storage_account.storage.resource_group_name} \
          --encryption-key-name ${var.encryption_key_name} \
          --encryption-key-version $key_version \
          --encryption-key-source Microsoft.Keyvault \
          --encryption-key-vault $key_vault_uri
    EOT
  }
}

resource "azurerm_monitor_diagnostic_setting" "storage-monitor" {
  count = var.monitoring_enabled == true ? 1 : 0

  name                           = "${replace(lower(var.resource_group_name), "_", "-")}-storage-account-monitor"
  target_resource_id             = azurerm_storage_account.storage.id
  log_analytics_workspace_id     = var.log_analytics_workspace_id
  log_analytics_destination_type = "Dedicated"

  log {
    category = "AuditEvent"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}

resource "azurerm_private_endpoint" "private_endpoint" {
  count               = var.private_link_subnet != null ? length(var.private_link_subresource_names) : 0
  name                = "${var.private_link_subnet.virtual_network_name}-${local.storage_account_full_name}-${var.private_link_subresource_names[count.index]}"
  location            = var.resource_group_location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_link_subnet.id
  private_service_connection {
    is_manual_connection           = false
    name                           = "${var.private_link_subnet.virtual_network_name}-${local.storage_account_full_name}-${var.private_link_subresource_names[count.index]}"
    private_connection_resource_id = azurerm_storage_account.storage.id
    subresource_names              = [var.private_link_subresource_names[count.index]]
  }
}

data "azurerm_private_endpoint_connection" "private_endpoint" {
  count               = var.private_link_subnet != null ? 1 : 0
  name                = azurerm_private_endpoint.private_endpoint.0.name
  resource_group_name = var.resource_group_name
  depends_on          = [azurerm_private_endpoint.private_endpoint]
}

resource "azurerm_role_assignment" "storage_account_contributors" {
  count                = length(var.storage_account_contributors)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = var.storage_account_contributors[count.index]
}

resource "azurerm_role_assignment" "data_readers" {
  count                = length(local.data_readers)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Reader and Data Access"
  principal_id         = local.data_readers[count.index]
}

resource "azurerm_role_assignment" "storage_blob_data_contributors" {
  count                = length(var.storage_blob_data_contributors)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.storage_blob_data_contributors[count.index]
}

resource "azurerm_role_assignment" "storage_blob_data_readers" {
  count                = length(var.storage_blob_data_readers)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = var.storage_blob_data_readers[count.index]
}

resource "azurerm_role_assignment" "storage_blob_data_owners" {
  count                = length(var.storage_blob_data_owners)
  scope                = azurerm_storage_account.storage.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.storage_blob_data_owners[count.index]
}
