# Azure Front Door Delivery Module

**Owner**: Delivery Teams  
**Purpose**: Deploy team-specific routes, origins, and configurations

## Responsibilities

This module allows teams to manage:
- ✅ Origin groups
- ✅ Origins (with Private Link support)
- ✅ Routes
- ✅ Custom domains
- ✅ Rule sets and rules
- ✅ Team-specific configuration

## Prerequisites

1. Platform team has deployed the platform module
2. You know the Front Door profile name
3. You know the shared endpoint name
4. You have appropriate RBAC permissions

## Usage

```hcl
module "team_a_routes" {
  source = "./modules/front-door-delivery"

  # Reference platform resources
  front_door_profile_name   = "company-frontdoor"
  front_door_resource_group = "rg-platform-networking"
  shared_endpoint_name      = "shared-endpoint"

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
        path                = "/health"
      }
    }
  }

  origins = {
    team_a_app = {
      name                           = "team-a-app"
      origin_group_key               = "team_a_apps"
      enabled                        = true
      host_name                      = "team-a-app.azurewebsites.net"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "team-a-app.azurewebsites.net"
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
      patterns_to_match      = ["/team-a/*"]  # Your team's path
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
```

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| `front_door_profile_name` | Front Door profile name (from platform) | `string` | yes |
| `front_door_resource_group` | Resource group (from platform) | `string` | yes |
| `shared_endpoint_name` | Shared endpoint name | `string` | yes |
| `origin_groups` | Your origin groups | `map(object)` | yes |
| `origins` | Your origins | `map(object)` | yes |
| `routes` | Your routes | `map(object)` | yes |

## Best Practices

### 1. Use Team-Specific Naming
```hcl
origin_groups = {
  team_name_apps = {  # Prefix with team name
    name = "team-name-origin-group"
    // ...
  }
}
```

### 2. Use Path-Based Routing
```hcl
routes = {
  my_route = {
    patterns_to_match = ["/team-a/*"]  # Your team's paths only
    // ...
  }
}
```

### 3. Enable Caching
```hcl
cache = {
  query_string_caching_behavior = "IgnoreQueryString"
  compression_enabled           = true
  content_types_to_compress     = ["text/html", "application/json"]
}
```

### 4. Use Health Probes
```hcl
health_probe = {
  protocol            = "Https"
  interval_in_seconds = 30
  request_type        = "GET"
  path                = "/health"  # Implement health endpoint
}
```

## Deployment

```bash
cd team-deployments/team-a
terraform init
terraform plan
terraform apply
```

## Private Link Example

For Premium SKU (set by platform team):

```hcl
origins = {
  private_app = {
    name         = "private-app"
    host_name    = "app.azurewebsites.net"
    // ...
    private_link = {
      request_message        = "Team A private link"
      target_type            = "sites"
      location               = "eastus"
      private_link_target_id = azurerm_app_service.team_app.id
    }
  }
}
```

**Don't forget to approve the private endpoint connection!**

## Troubleshooting

### "Front Door profile not found"
- Verify `front_door_profile_name` matches platform deployment
- Check `front_door_resource_group` is correct
- Verify you have read access to the resource group

### "Endpoint not found"
- Verify `shared_endpoint_name` matches platform deployment
- Ask platform team for correct endpoint name

### Route conflicts
- Ensure your `patterns_to_match` don't overlap with other teams
- Use team-specific paths: `/team-name/*`

## Support

For questions contact:
- Your team lead
- Platform team: platform-team@company.com
