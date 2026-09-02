# Compliance fixture for the front-door-platform module.
# Calls the module directly — the module creates all its own resources and has
# no data source lookups, so terraform plan succeeds without real Azure infrastructure.

module "platform" {
  source = "../../"

  resource_group_name = var.resource_group_name
  front_door_name     = var.front_door_name
  sku_name            = var.sku_name

  waf_policy_name = var.waf_policy_name
  waf_mode        = var.waf_mode

  shared_endpoints = var.shared_endpoints

  tags = var.tags
}
