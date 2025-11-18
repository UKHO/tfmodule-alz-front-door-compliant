terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  # Using Azure CLI authentication
}

resource "azurerm_resource_group" "example" {
  name     = "rg-frontdoor-privatelink-example"
  location = "East US"
}

# Platform team would deploy this
module "front_door_platform" {
  source = "../../modules/front-door-platform"

  front_door_name     = "fd-privatelink-example"
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Premium_AzureFrontDoor"  # Required for Private Link
  waf_policy_name     = "wafprivatelink"
  waf_mode            = "Prevention"

  shared_endpoints = {
    default = {
      name    = "private-endpoint"
      enabled = true
    }
  }

  tags = {
    Environment = "Development"
    Example     = "PrivateLink"
    ManagedBy   = "Terraform"
  }
}

# Delivery team would deploy this (using their own state file)
module "team_private_routes" {
  source = "../../modules/front-door-delivery"

  # Reference platform-deployed resources
  front_door_profile_name   = module.front_door_platform.front_door_name
  front_door_resource_group = azurerm_resource_group.example.name
  shared_endpoint_name      = "private-endpoint"

  origin_groups = {
    private_apps = {
      name                     = "private-apps-group"
      session_affinity_enabled = false
      load_balancing = {
        sample_size                        = 4
        successful_samples_required        = 3
        additional_latency_in_milliseconds = 50
      }
      health_probe = {
        protocol            = "Https"
        interval_in_seconds = 30
        request_type        = "GET"
        path                = "/"
      }
    }
  }

  origins = {
    private_app = {
      name                           = "private-app-origin"
      origin_group_key               = "private_apps"
      enabled                        = true
      host_name                      = azurerm_linux_web_app.example.default_hostname
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = azurerm_linux_web_app.example.default_hostname
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = true

      # Private Link configuration
      private_link = {
        request_message        = "Front Door Private Link connection for secure access"
        target_type            = "sites"
        location               = azurerm_resource_group.example.location
        private_link_target_id = azurerm_linux_web_app.example.id
      }
    }
  }

  routes = {
    default = {
      name                   = "private-route"
      origin_group_key       = "private_apps"
      origin_keys            = ["private_app"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Https"]
      link_to_default_domain = true
      cache = {
        query_string_caching_behavior = "IgnoreQueryString"
        compression_enabled           = true
        content_types_to_compress     = ["text/html", "text/css", "application/javascript"]
      }
    }
  }

  tags = {
    Environment = "Development"
    Example     = "PrivateLink"
    Network     = "Private"
    ManagedBy   = "Terraform"
  }
}

output "front_door_endpoint" {
  value       = module.front_door_platform.endpoint_host_names["default"]
  description = "Front Door endpoint - use this to access your private app"
}
