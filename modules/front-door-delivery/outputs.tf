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

output "origin_group_names" {
  description = "A map of origin group names, as created on the shared profile."
  value       = { for k, v in azurerm_cdn_frontdoor_origin_group.this : k => v.name }
}

output "origin_names" {
  description = "A map of origin names, as created on the shared profile."
  value       = { for k, v in azurerm_cdn_frontdoor_origin.this : k => v.name }
}

output "route_names" {
  description = "A map of route names, as created on the shared endpoint."
  value       = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.name }
}

output "route_patterns_to_match" {
  description = "A map of each route's patterns_to_match, as created on the shared endpoint."
  value       = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.patterns_to_match }
}

output "route_origin_ids" {
  description = "A map of each route's resolved origin IDs (cdn_frontdoor_origin_ids)."
  value       = { for k, v in azurerm_cdn_frontdoor_route.this : k => v.cdn_frontdoor_origin_ids }
}

output "rule_set_names" {
  description = "A map of rule set names, as created on the shared profile."
  value       = { for k, v in azurerm_cdn_frontdoor_rule_set.this : k => v.name }
}

output "custom_domain_names" {
  description = "A map of custom domain names, as created on the shared profile."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.name }
}

output "custom_domain_host_names" {
  description = "A map of custom domain host names, as created on the shared profile."
  value       = { for k, v in azurerm_cdn_frontdoor_custom_domain.this : k => v.host_name }
}
