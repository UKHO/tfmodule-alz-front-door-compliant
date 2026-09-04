# Shared platform prerequisite for the delivery-module overlap tests.
#
# Replicates what the platform team's front-door-platform module normally owns: a
# Front Door profile, one shared endpoint, and a DNS zone for custom-domain
# attachment. Two front-door-delivery instances (tests/main.tf) are then pointed
# at these SAME shared resources by name — exactly as two independent delivery
# teams would be in production — so the overlap tests can prove neither instance
# can affect or override the other's routes, origins, origin groups, rule sets or
# custom domains on the shared endpoint/profile.
#
# Endpoint names form part of a globally unique public hostname
# (<name>.z01.azurefd.net), so a random suffix is appended to avoid collisions
# with unrelated Azure tenants.

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_resource_group" "shared" {
  name     = "${var.resource_group_name_prefix}-platform-${random_string.suffix.result}"
  location = var.location

  tags = {
    environment  = var.environment_tag
    "managed-by" = var.managed_by_tag
  }
}

resource "azurerm_cdn_frontdoor_profile" "shared" {
  name                = "${var.front_door_profile_name}-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.shared.name
  sku_name            = "Standard_AzureFrontDoor"

  tags = {
    environment  = var.environment_tag
    "managed-by" = var.managed_by_tag
  }
}

resource "azurerm_cdn_frontdoor_endpoint" "shared" {
  name                     = "${var.shared_endpoint_name}-${random_string.suffix.result}"
  cdn_frontdoor_profile_id = azurerm_cdn_frontdoor_profile.shared.id

  tags = {
    environment  = var.environment_tag
    "managed-by" = var.managed_by_tag
  }
}

resource "azurerm_dns_zone" "shared" {
  name                = var.dns_zone_name
  resource_group_name = azurerm_resource_group.shared.name

  tags = {
    environment  = var.environment_tag
    "managed-by" = var.managed_by_tag
  }
}
