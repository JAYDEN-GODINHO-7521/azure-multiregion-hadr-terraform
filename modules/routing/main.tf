resource "azurerm_traffic_manager_profile" "this" {
  name                   = var.profile_name
  resource_group_name    = var.resource_group_name
  traffic_routing_method = var.traffic_routing_method
  tags                   = var.tags

  dns_config {
    relative_name = var.dns_label
    ttl           = var.ttl_seconds
  }

  monitor_config {
    protocol                     = var.probe_protocol
    port                         = var.probe_port
    path                         = var.health_probe_path
    interval_in_seconds          = var.probe_interval_seconds
    timeout_in_seconds           = 5
    tolerated_number_of_failures = 2
    expected_status_code_ranges  = ["200-299"]
  }
}

resource "azurerm_traffic_manager_external_endpoint" "regional" {
  for_each = var.origins

  name                = "ep-${each.key}"
  profile_id          = azurerm_traffic_manager_profile.this.id
  target              = each.value.host_name
  enabled             = each.value.enabled
  priority            = each.value.priority
  weight              = each.value.weight
  always_serve_enabled = false

  custom_header {
    name  = "Host"
    value = each.value.origin_host_header
  }
}