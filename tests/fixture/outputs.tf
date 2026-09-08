output "front_door_profile_name" {
  description = "Name of the shared Front Door profile — passed into the harness under test via -var-file."
  value       = azurerm_cdn_frontdoor_profile.shared.name
}

output "front_door_resource_group" {
  description = "Resource group containing the shared Front Door profile — passed into the harness under test via -var-file."
  value       = azurerm_resource_group.shared.name
}

output "shared_endpoint_name" {
  description = "Name of the shared endpoint — passed into the harness under test via -var-file."
  value       = azurerm_cdn_frontdoor_endpoint.shared.name
}

output "dns_zone_id" {
  description = "Resource ID of the throwaway DNS zone — passed into the harness under test via -var-file."
  value       = azurerm_dns_zone.shared.id
}

output "dns_zone_name" {
  description = "Name of the throwaway DNS zone — passed into the harness under test via -var-file."
  value       = azurerm_dns_zone.shared.name
}
