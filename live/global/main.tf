resource "azurerm_resource_group" "global" {
  name     = "rg-ha-dr-global"
  location = "indiasouthcentral"
}

module "routing" {
  source = "../../modules/routing"

  profile_name           = "tm-hadr-global"
  dns_label              = "tm-hadr-9482" # resolves to tm-hadr-9482.trafficmanager.net
  resource_group_name    = azurerm_resource_group.global.name
  traffic_routing_method = "Weighted"
  ttl_seconds            = 30
  health_probe_path      = "/"
  probe_protocol         = "HTTP"
  probe_port             = 80
  probe_interval_seconds = 10

  origins = {
    eastus = {
      host_name          = var.eastus_origin_hostname
      origin_host_header = var.eastus_origin_hostname
      priority           = 1
      weight             = 500
      enabled            = true
    }
    westus = {
      host_name          = var.westus_origin_hostname
      origin_host_header = var.westus_origin_hostname
      priority           = 2
      weight             = 500
      enabled            = true
    }
  }
}
