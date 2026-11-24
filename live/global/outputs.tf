output "traffic_manager_fqdn" {
  description = "Public FQDN of the Azure Traffic Manager profile"
  value       = module.routing.fqdn
}