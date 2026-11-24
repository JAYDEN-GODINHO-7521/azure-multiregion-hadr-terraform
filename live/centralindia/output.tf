output "cosmos_endpoint" {
  description = "Cosmos DB endpoint URL"
  value       = module.cosmosdb.endpoint
}

output "cosmos_primary_connection_string" {
  description = "Cosmos DB primary SQL connection string"
  value       = module.cosmosdb.primary_connection_string
  sensitive   = true
}