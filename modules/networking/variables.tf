variable "name_prefix" {
    description = "Prefix used for naming networking resources"
    type = string
}

variable "location" {
    description = "Azure region for this VNet stack"
    type = string
}

variable "resource_group_name" {
    description = "Target resource group name"
    type = string
}

variable "vnet_address_space" {
    description = "Address space CIDR for the region VNet"
    type = list(string)
}

variable "aks_subnet_prefixes" {
    description = "CIDR prefixes for the AKS workload subnet"
    type = list(string)
}

variable "pe_subnet_prefixes" {
    description = "CIDR prefixes for Private Endpoints"
    type = list(string)
}

variable "peer_vnet_id" {
  description = "Resource ID of the remote VNet to peer with (optional on first apply)"
  type        = string
  default     = null
}

variable "peer_vnet_name" {
    description = "Name of the remote VNet to peer with"
    type = string
    default = null
}

variable "private_dns_zones" {
  description = "List of Private DNS zone names to create and link to this VNet"
  type        = list(string)
  default = [
    "privatelink.documents.azure.com",
    "privatelink.vaultcore.azure.net"
  ]
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}