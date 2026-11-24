variable "account_name" {
  description = "Globally unique name for the Azure Cosmos DB account"
  type        = string
}

variable "location" {
  description = "Primary Azure region for the Cosmos DB account"
  type        = string
}

variable "secondary_location" {
  description = "Secondary Azure region for geo-replication"
  type        = string
}

variable "resource_group_name" {
  description = "Target resource group name"
  type        = string
}

variable "pe_subnet_id" {
  description = "Subnet ID where the Cosmos DB Private Endpoint is placed"
  type        = string
}

variable "private_dns_zone_id" {
  description = "Private DNS zone ID for privatelink.documents.azure.com"
  type        = string
}

variable "consistency_level" {
  description = "Cosmos DB consistency level (Strong, BoundedStaleness, Session, ConsistentPrefix, Eventual)"
  type        = string
  default     = "Session"
}

variable "database_name" {
  description = "Application database name"
  type        = string
  default     = "appdb"
}

variable "container_name" {
  description = "Application container name"
  type        = string
  default     = "items"
}

variable "partition_key_path" {
  description = "Partition key path for the container"
  type        = string
  default     = "/tenantId"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}