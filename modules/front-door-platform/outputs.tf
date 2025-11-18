output "front_door_id" {
  description = "The ID of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.id
}

output "front_door_name" {
  description = "The name of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.name
}

output "resource_group_name" {
  description = "The resource group name containing the Front Door."
  value       = var.resource_group_name
}

output "waf_policy_id" {
  description = "The ID of the WAF policy."
  value       = azurerm_cdn_frontdoor_firewall_policy.this.id
}

output "endpoint_ids" {
  description = "A map of endpoint IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.id }
}

output "endpoint_host_names" {
  description = "A map of endpoint host names."
  value       = { for k, v in azurerm_cdn_frontdoor_endpoint.this : k => v.host_name }
}

output "sku_name" {
  description = "The SKU name of the Front Door profile."
  value       = azurerm_cdn_frontdoor_profile.this.sku_name
}
