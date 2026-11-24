resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = var.resource_group_name
  dns_prefix          = "${var.cluster_name}-dns"
  sku_tier            = "Free" # Recommended for production SLA; use "Free" for dev/test

  # Enable OIDC issuer and Workload Identity for pod-level Entra ID authentication
  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  node_provisioning_profile {
    mode = var.node_provisioning_mode
  }

  default_node_pool {
    name                 = "systempool"
    vm_size              = var.node_vm_size
    vnet_subnet_id       = var.aks_subnet_id
    auto_scaling_enabled = true
    min_count            = var.min_node_count
    max_count            = var.max_node_count
    os_disk_size_gb      = 30
    type                 = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin = "azure"
    network_policy = "calico"
    service_cidr   = "172.16.0.0/16"
    dns_service_ip = "172.16.0.10"
  }

  key_vault_secrets_provider {
    secret_rotation_enabled = true
  }
}

resource "azurerm_kubernetes_cluster_node_pool" "apps" {
  name                  = "appspool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = var.node_vm_size
  vnet_subnet_id        = var.aks_subnet_id
  auto_scaling_enabled  = true
  min_count             = var.min_node_count
  max_count             = var.max_node_count
  os_disk_size_gb       = 64
  mode                  = "User"
}

# Allow AKS cluster identity to manage networking on the delegated subnet
resource "azurerm_role_assignment" "aks_net_contributor" {
  scope                = var.aks_subnet_id
  role_definition_name = "Network Contributor"
  principal_id         = azurerm_kubernetes_cluster.this.identity[0].principal_id
}

# Dedicated User-Assigned Managed Identity for workloads reading Key Vault secrets
resource "azurerm_user_assigned_identity" "kv_workload" {
  name                = "${var.cluster_name}-kv-workload-id"
  location            = var.location
  resource_group_name = var.resource_group_name
}

# Federate the Kubernetes ServiceAccount with the User-Assigned Managed Identity
resource "azurerm_federated_identity_credential" "kv_workload" {
  name                = "${var.cluster_name}-kv-workload-fic"
  audience            = ["api://AzureADTokenExchange"]
  issuer              = azurerm_kubernetes_cluster.this.oidc_issuer_url
  subject             = "system:serviceaccount:${var.workload_namespace}:${var.workload_service_account}"
  user_assigned_identity_id = azurerm_user_assigned_identity.kv_workload.id
}

# Grant least-privilege Key Vault secret read access to the workload identity
resource "azurerm_role_assignment" "workload_kv_secrets_user" {
  scope                = var.key_vault_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.kv_workload.principal_id
}