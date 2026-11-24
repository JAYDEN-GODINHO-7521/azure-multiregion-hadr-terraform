variable "vault_name" {
  description = "Globally unique Key Vault name (3-24 alphanumeric chars and hyphens)"
  type        = string
}

variable "location" {
  description = "Azure region for the Key Vault"
  type        = string
}

variable "resource_group_name" {
  description = "Target resource group name"
  type        = string
}

variable "pe_subnet_id" {
  description = "Subnet ID where the Key Vault Private Endpoint is placed"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.vaultcore.azure.net"
  type        = string
}

variable "cosmos_endpoint" {
  description = "Cosmos DB endpoint URL to store as a secret"
  type        = string
}

variable "cosmos_connection_string" {
  description = "Cosmos DB primary connection string to store as a secret"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}