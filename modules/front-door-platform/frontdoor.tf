resource "azurerm_cdn_frontdoor_profile" "this" {
  name                = var.front_door_name
  resource_group_name = var.resource_group_name
  sku_name            = var.sku_name
  tags                = var.tags

  timeouts {
    create = "90m"  # Front Door can take a long time to create
    update = "90m"
    delete = "90m"  # Deletions especially can take 30-60 minutes
    read   = "5m"
  }
}
