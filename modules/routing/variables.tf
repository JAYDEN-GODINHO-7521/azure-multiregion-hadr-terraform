variable "profile_name" {
  description = "Name of the Azure Traffic Manager profile"
  type        = string
}

variable "dns_label" {
  description = "Relative DNS label under trafficmanager.net (must be globally unique)"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name for the Traffic Manager profile"
  type        = string
}

variable "traffic_routing_method" {
  description = "Routing method: Priority, Weighted, Performance, Geographic, MultiValue, or Subnet"
  type        = string
  default     = "Weighted"
}

variable "ttl_seconds" {
  description = "DNS TTL in seconds for Traffic Manager responses"
  type        = number
  default     = 30
}

variable "origins" {
  description = "Map of regional endpoints (e.g., eastus and westus)"
  type = map(object({
    host_name          = string
    origin_host_header = string
    priority           = number # 1..1000 (lower number = higher priority when using Priority routing)
    weight             = number # 1..1000 (used when using Weighted routing)
    enabled            = bool
  }))
}

variable "health_probe_path" {
  description = "HTTP/HTTPS path probed by Traffic Manager to assess endpoint health"
  type        = string
  default     = "/healthz"
}

variable "probe_protocol" {
  description = "Protocol used by Traffic Manager health probes: HTTP or HTTPS"
  type        = string
  default     = "HTTP"
}

variable "probe_port" {
  description = "Port probed by Traffic Manager (80 for HTTP, 443 for HTTPS)"
  type        = number
  default     = 80
}

variable "probe_interval_seconds" {
  description = "Health probe interval in seconds (10 or 30)"
  type        = number
  default     = 10
}

variable "tags" {
  description = "Tags applied to all resources"
  type        = map(string)
  default     = {}
}