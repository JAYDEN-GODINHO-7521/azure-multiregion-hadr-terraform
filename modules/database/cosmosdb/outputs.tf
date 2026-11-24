output "account_id" {
  value = azurerm_cosmosdb_account.this.id
}

output "endpoint" {
  value = azurerm_cosmosdb_account.this.endpoint
}

output "primary_connection_string" {
  value     = azurerm_cosmosdb_account.this.primary_sql_connection_string
  sensitive = true
}

output "primary_readonly_connection_string" {
  value     = azurerm_cosmosdb_account.this.secondary_sql_connection_string
  sensitive = true
}