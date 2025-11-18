terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
  # Using Azure CLI authentication (already logged in with 'az login')
}

resource "azurerm_resource_group" "platform" {
  name     = "rg-platform-networking"
  location = "East US"
}

module "front_door_platform" {
  source = "../../modules/front-door-platform"

  front_door_name     = "company-frontdoor"
  resource_group_name = azurerm_resource_group.platform.name
  sku_name            = "Premium_AzureFrontDoor"
  waf_policy_name     = "wafplatform"
  waf_mode            = "Prevention"

  shared_endpoints = {
    shared = {
      name    = "shared-endpoint"
      enabled = true
    }
  }

  tags = {
    ManagedBy   = "Platform-Team"
    Environment = "Shared"
    CostCenter  = "Platform"
  }
}

output "front_door_info" {
  value = {
    profile_name         = module.front_door_platform.front_door_name
    resource_group       = module.front_door_platform.resource_group_name
    shared_endpoint_name = "shared-endpoint"
    endpoint_hostname    = module.front_door_platform.endpoint_host_names["shared"]
  }
  description = "Share these values with delivery teams"
}
