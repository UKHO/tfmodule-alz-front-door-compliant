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
  features {}
  # Using Azure CLI authentication (already logged in with 'az login')
  # Or set ARM_SUBSCRIPTION_ID environment variable
}

# Team's application resources
resource "azurerm_resource_group" "team_a" {
  name     = "rg-team-a-apps"
  location = "East US"
}

# Example: Team's App Service
resource "azurerm_service_plan" "team_a" {
  name                = "asp-team-a"
  location            = azurerm_resource_group.team_a.location
  resource_group_name = azurerm_resource_group.team_a.name
  os_type             = "Linux"
  sku_name            = "P1v3"
}

resource "azurerm_linux_web_app" "team_a" {
  name                = "app-team-a-${random_string.unique.result}"
  location            = azurerm_resource_group.team_a.location
  resource_group_name = azurerm_resource_group.team_a.name
  service_plan_id     = azurerm_service_plan.team_a.id

  site_config {
    always_on = true
  }
}

resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

# Team's Front Door configuration
module "team_a_routes" {
  source = "../../modules/front-door-delivery"

  # Reference platform-deployed resources
  # UPDATE THESE VALUES to match your platform deployment:
  front_door_profile_name   = "company-frontdoor"       # From platform output
  front_door_resource_group = "rg-platform-networking"  # From platform output
  shared_endpoint_name      = "shared-endpoint"         # From platform output

  origin_groups = {
    team_a_apps = {
      name                     = "team-a-origin-group"
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
    team_a_app = {
      name                           = "team-a-app"
      origin_group_key               = "team_a_apps"
      enabled                        = true
      host_name                      = azurerm_linux_web_app.team_a.default_hostname
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = azurerm_linux_web_app.team_a.default_hostname
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = true
    }
  }

  routes = {
    team_a_route = {
      name                   = "team-a-route"
      origin_group_key       = "team_a_apps"
      origin_keys            = ["team_a_app"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/team-a/*", "/api/team-a/*"]
      supported_protocols    = ["Https"]
      link_to_default_domain = true
      cache = {
        query_string_caching_behavior = "IgnoreQueryString"
        compression_enabled           = true
        content_types_to_compress     = ["text/html", "application/json"]
      }
    }
  }

  tags = {
    Team      = "TeamA"
    ManagedBy = "TeamA"
    Project   = "ApplicationA"
  }
}

output "team_access_url" {
  value       = "https://${module.team_a_routes.route_ids["team_a_route"]}/team-a/"
  description = "Access your application at this URL (after DNS propagation)"
}
