resource "azurerm_cdn_frontdoor_endpoint" "this" {
  for_each = var.shared_endpoints

  name                     = each.value.name
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.this.id
  enabled                  = each.value.enabled
  tags                     = merge(var.tags, each.value.tags)
}
