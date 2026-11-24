resource "azurerm_cosmosdb_account" "this" {
  name                = var.account_name
  location            = var.location
  resource_group_name = var.resource_group_name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  public_network_access_enabled = false
  is_virtual_network_filter_enabled = true

  multiple_write_locations_enabled = true
  automatic_failover_enabled       = true

  free_tier_enabled = true

  consistency_policy {
    consistency_level       = var.consistency_level
    max_interval_in_seconds = var.consistency_level == "BoundedStaleness" ? 10 : null
    max_staleness_prefix    = var.consistency_level == "BoundedStaleness" ? 200 : null
  }

  geo_location {
    location          = var.location
    failover_priority = 0
    zone_redundant    = false
  }

  geo_location {
    location          = var.secondary_location
    failover_priority = 1
    zone_redundant    = false
  }

  tags = var.tags
}

resource "azurerm_cosmosdb_sql_database" "this" {
  name                = var.database_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "this" {
  name                = var.container_name
  resource_group_name = azurerm_cosmosdb_account.this.resource_group_name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.this.name
  partition_key_paths = [var.partition_key_path]
  throughput          = 400
}

resource "azurerm_private_endpoint" "cosmos" {
  name                = "pe-${var.account_name}-${var.location}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.pe_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-${var.account_name}-${var.location}"
    private_connection_resource_id = azurerm_cosmosdb_account.this.id
    subresource_names              = ["Sql"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-group-cosmos"
    private_dns_zone_ids = [var.private_dns_zone_id]
  }
}