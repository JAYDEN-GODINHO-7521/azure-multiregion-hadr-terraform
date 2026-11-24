variable "eastus_origin_hostname" {
  description = "Public FQDN or IP of the East US AKS ingress/load balancer"
  type        = string
}

variable "westus_origin_hostname" {
  description = "Public FQDN or IP of the West US AKS ingress/load balancer"
  type        = string
}