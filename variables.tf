#
## Variables Configuration
#
#

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group for the Storage Account"
}

variable "resource_group_location" {
  type        = string
  description = "Location of the resource group for the Storage Account"
}

# https://nokia.sharepoint.com/sites/it/netcon/WAN/Pages/Webproxy.aspx
variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of IP or IP ranges in CIDR Format (only public IP). NOTE: /31 blocks are not supported and instead should be given as two /32 blocks."
  default     = []
}

variable "key_vault_id" {
  type        = string
  description = "ID of the key-vault"
}

variable "encryption_key_name" {
  type        = string
  description = "Name of the encryption key from the key-vault"
  default = null
}

variable "tags" {
  type        = map
  description = "Tags for the NVDC subscription"
}

variable "storage_account_subnet_id" { # deprecated use: subnet_ids
  type        = string
  description = "Subnet ID what is allowed to connect this storage account"
  default     = ""
}

variable "subnet_ids" {
  type        = list
  description = "List of subnet ID what is allowed to connect this storage account"
  default     = []
}

variable "storage_account_full_name" {
  type        = string
  description = "The full name of the Storage Account to create"
  default     = ""
}

variable "storage_account_name" {
  type        = string
  description = "The name of the Storage Account to create"
  default     = "storage"
}

variable "storage_container_names" {
  type        = list(string)
  description = "List of Container names to create within the Storage Account"
  default     = []
}

variable "storage_data_lake_gen2_name" { # derprecated: use storage_data_lake_gen2_names
  type        = string
  description = "Name of the Data Lake Gen2 File System"
  default     = ""
}


variable "storage_data_lake_gen2_names" {
  type        = list(string)
  description = "Names of the Data Lake Gen2 File Systems"
  default     = []
}

variable "storage_data_lake_gen2_properties" {
  type        = map
  description = "Map of Keys to Base64-Encoded Values which should be assigned to this Data Lake Gen2 File System"
  default     = {}
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "ID of a Log Analytics Workspace where Diagnostics Data should be sent"
  default = null
}

variable "monitoring_enabled" {
  default = true
}

variable "encryption_enabled" {
  default = true
}

variable "private_link_subnet" {
  default = null
}

variable "private_link_subresource_names" {
  default = ["blob"]
}

variable "storage_account_contributors" {
  type    = list(string)
  default = []
}

variable "storage_blob_data_contributors" {
  type    = list(string)
  default = []
}

variable "storage_blob_data_readers" {
  type    = list(string)
  default = []
}

variable "storage_blob_data_owners" {
  type    = list(string)
  default = []
}

variable "container_access_type" {
  type    = string
  default = "private"
}

variable "delete_retention_policy_days" {
  type        = number
  default     = 0
  description = "Enable soft-delete and set retention period. 1 and 365"
}

variable "prevent_delete" {
  type    = bool
  default = false
}
