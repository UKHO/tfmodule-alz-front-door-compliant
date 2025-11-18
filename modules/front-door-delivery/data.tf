data "azurerm_cdn_frontdoor_profile" "shared" {
  name                = var.front_door_profile_name
  resource_group_name = var.front_door_resource_group
}

data "azurerm_cdn_frontdoor_endpoint" "shared" {
  name                = var.shared_endpoint_name
  profile_name        = data.azurerm_cdn_frontdoor_profile.shared.name
  resource_group_name = var.front_door_resource_group
}
