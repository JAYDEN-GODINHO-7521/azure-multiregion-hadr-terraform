variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "location" {
  description = "Azure region for the AKS cluster"
  type        = string
}

variable "resource_group_name" {
  description = "Target resource group name"
  type        = string
}

variable "aks_subnet_id" {
  description = "Subnet ID where AKS nodes and pods are placed"
  type        = string
}

variable "key_vault_id" {
  description = "Resource ID of the regional Azure Key Vault"
  type        = string
}

variable "node_vm_size" {
  description = "VM SKU size for system and app node pools"
  type        = string
  default     = "Standard_D2s_v5"
}

variable "min_node_count" {
  description = "Minimum nodes per autoscaled pool (keep >= 2 for HA/thundering herd buffer)"
  type        = number
  default     = 2
}

variable "max_node_count" {
  description = "Maximum nodes per autoscaled pool"
  type        = number
  default     = 6
}

variable "workload_namespace" {
  description = "Kubernetes namespace for the application workload"
  type        = string
  default     = "app"
}

variable "workload_service_account" {
  description = "Kubernetes ServiceAccount federated with the workload identity"
  type        = string
  default     = "app-sa"
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "node_provisioning_mode" {
  description = "AKS node provisioning mode (e.g., Manual or Auto)"
  type        = string
  default     = "Manual"
}