resource "azurerm_resource_group" "net" {
  name     = "rg-ha-dr-net-Central-India"
  location = "Centralindia"
}

module "networking" {
  source = "../../modules/networking"

  name_prefix         = "hadr"
  location            = "centralindia"
  resource_group_name = azurerm_resource_group.net.name
  vnet_address_space  = ["10.10.0.0/16"]
  aks_subnet_prefixes = ["10.10.0.0/22"]
  pe_subnet_prefixes  = ["10.10.8.0/24"]

  # Set this in Pass 2 after west-us VNet is created
  peer_vnet_id   =   try("/subscriptions/1165b150-2a4e-4bde-b9eb-33d712eb910d/resourceGroups/rg-ha-dr-net-indiasouthcentral/providers/Microsoft.Network/virtualNetworks/hadr-vnet-indiasouthcentral",null)
}

module "cosmosdb" {
  source = "../../modules/database/cosmosdb"

  account_name        = "cosmos-hadr-centralindia-9481" 
  location            = "centralindia"
  secondary_location  = "indiasouthcentral"
  resource_group_name = azurerm_resource_group.net.name
  pe_subnet_id        = module.networking.pe_subnet_id
  private_dns_zone_id = module.networking.private_dns_zone_ids["privatelink.documents.azure.com"]
  consistency_level   = "Session"
}

module "keyvault" {
  source = "../../modules/database/keyvault"

  vault_name               = "kvhadrcentralindia9481" 
  location                 = "centralindia"
  resource_group_name      = azurerm_resource_group.net.name
  pe_subnet_id             = module.networking.pe_subnet_id
  private_dns_zone_id      = module.networking.private_dns_zone_ids["privatelink.vaultcore.azure.net"]
  cosmos_endpoint          = module.cosmosdb.endpoint
  cosmos_connection_string = module.cosmosdb.primary_connection_string
}

module "compute" {
  source = "../../modules/compute"

  cluster_name           = "aks-hadr-centralindia"
  location               = "centralindia"
  resource_group_name    = azurerm_resource_group.net.name
  aks_subnet_id          = module.networking.aks_subnet_id
  key_vault_id           = module.keyvault.key_vault_id
  node_provisioning_mode = "Manual"
  node_vm_size           = "Standard_D2s_v5"
  min_node_count         = 1
  max_node_count         = 6
  workload_namespace     = "app"
  workload_service_account = "app-sa"
}