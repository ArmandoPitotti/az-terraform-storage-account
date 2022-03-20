output "storage_account_id" {
  value       = azurerm_storage_account.storage.id
  description = "ID of the Storage Account"

  #depends_on = [module.subnets]
}

output "name" {
  value       = azurerm_storage_account.storage.name
  description = "Name of the Storage Account"

  #depends_on = [module.subnets]
}

output "storage_account_access_key" {
  value       = azurerm_storage_account.storage.primary_access_key
  description = "Access key for the Storage Account"

  #depends_on = [module.subnets]
}

output "storage_container_names" {
  value       = azurerm_storage_container.storage[*].name
  description = "List of Storage Container names"

  #depends_on = [module.subnets]
}

output "storage_container_ids" {
  value       = azurerm_storage_container.storage[*].id
  description = "List of Storage Container IDs"

  #depends_on = [module.subnets]
}

output "storage_data_lake_gen2_id" { # Deprecated: use storage_data_lake_gen2_ids
  value       = azurerm_storage_data_lake_gen2_filesystem.storage[*].id
  description = "List of Data Lake Storage Gen2 ID"

  #depends_on = [module.subnets]
}

output "storage_data_lake_gen2_ids" {
  value       = azurerm_storage_data_lake_gen2_filesystem.storage[*].id
  description = "List of Data Lake Storage Gen2 ID"

  #depends_on = [module.subnets]
}

output "storage_data_lake_gen2_map_ids" {
  value = {
    for filesystem in azurerm_storage_data_lake_gen2_filesystem.storage :
    filesystem.name => "${azurerm_storage_account.storage.id}/blobServices/default/containers/${filesystem.name}"
  }
  description = "Name map of Data Lake Storage Gen2 ID"

  #depends_on = [module.subnets]
}

output "primary_blob_host" {
  value = azurerm_storage_account.storage.primary_blob_host

  #depends_on = [module.subnets]
}

output "storage_account_primary_blob_endpoint" {
  value       = azurerm_storage_account.storage.primary_blob_endpoint
  description = "Primary blob endpoint"

  #depends_on = [module.subnets]
}

output "resource_group_name" {
  value = azurerm_storage_account.storage.resource_group_name
}

output "private_endpoint_address" {
  value = var.private_link_subnet != null ? data.azurerm_private_endpoint_connection.private_endpoint.0.private_service_connection.0.private_ip_address : null
}

output "primary_connection_string" {
  value = azurerm_storage_account.storage.primary_connection_string
}
