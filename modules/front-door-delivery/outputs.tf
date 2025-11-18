output "origin_group_ids" {
  description = "A map of origin group IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.id }
}

output "origin_ids" {
  description = "A map of origin IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_origin.this : k => v.id }
}

output "route_ids" {
  description = "A map of route IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.id }
}

output "custom_domain_ids" {
  description = "A map of custom domain IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.id }
}

output "custom_domain_validation_tokens" {
  description = "A map of custom domain validation tokens for DNS verification."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.validation_token }
}

output "rule_set_ids" {
  description = "A map of rule set IDs."
  value       = { for k, v in azurerm_cdn_frontdoor_rule_set.this : k => v.id }
}
