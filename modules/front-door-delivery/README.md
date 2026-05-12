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

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 4.72.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_cdn_frontdoor_custom_domain.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_custom_domain) | resource |
| [azurerm_cdn_frontdoor_origin.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin) | resource |
| [azurerm_cdn_frontdoor_origin_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_origin_group) | resource |
| [azurerm_cdn_frontdoor_route.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_route) | resource |
| [azurerm_cdn_frontdoor_rule.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule) | resource |
| [azurerm_cdn_frontdoor_rule_set.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_rule_set) | resource |
| [azurerm_cdn_frontdoor_endpoint.shared](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cdn_frontdoor_endpoint) | data source |
| [azurerm_cdn_frontdoor_profile.shared](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/cdn_frontdoor_profile) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_custom_domains"></a> [custom\_domains](#input\_custom\_domains) | A map of custom domains for this team's applications. | <pre>map(object({<br/>    name        = string<br/>    dns_zone_id = string<br/>    host_name   = string<br/>    tls = object({<br/>      certificate_type        = string<br/>      minimum_tls_version     = string<br/>      cdn_frontdoor_secret_id = optional(string)<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_front_door_profile_name"></a> [front\_door\_profile\_name](#input\_front\_door\_profile\_name) | The name of the existing Front Door profile created by platform team. | `string` | n/a | yes |
| <a name="input_front_door_resource_group"></a> [front\_door\_resource\_group](#input\_front\_door\_resource\_group) | The resource group containing the Front Door profile. | `string` | n/a | yes |
| <a name="input_origin_groups"></a> [origin\_groups](#input\_origin\_groups) | A map of origin groups for this team's applications. | <pre>map(object({<br/>    name                     = string<br/>    session_affinity_enabled = bool<br/>    load_balancing = object({<br/>      sample_size                        = number<br/>      successful_samples_required        = number<br/>      additional_latency_in_milliseconds = number<br/>    })<br/>    health_probe = optional(object({<br/>      protocol            = string<br/>      interval_in_seconds = number<br/>      request_type        = string<br/>      path                = string<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_origins"></a> [origins](#input\_origins) | A map of origins for this team's applications.<br/><br/>Private Link Integration (Premium SKU only):<br/>- Set private\_link block to connect to private endpoints in VNets<br/>- Supported target\_types: blob, blob\_secondary, web, sites, table, queue, file<br/>- Requires Premium\_AzureFrontDoor SKU (set by platform team)<br/>- Origin must have a private endpoint configured | <pre>map(object({<br/>    name                           = string<br/>    origin_group_key               = string<br/>    enabled                        = bool<br/>    host_name                      = string<br/>    http_port                      = number<br/>    https_port                     = number<br/>    origin_host_header             = string<br/>    priority                       = number<br/>    weight                         = number<br/>    certificate_name_check_enabled = bool<br/>    private_link = optional(object({<br/>      request_message        = string<br/>      target_type            = string<br/>      location               = string<br/>      private_link_target_id = string<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_routes"></a> [routes](#input\_routes) | A map of routes for this team's applications. | <pre>map(object({<br/>    name                   = string<br/>    origin_group_key       = string<br/>    origin_keys            = list(string)<br/>    enabled                = bool<br/>    forwarding_protocol    = string<br/>    https_redirect_enabled = bool<br/>    patterns_to_match      = list(string)<br/>    supported_protocols    = list(string)<br/>    custom_domain_keys     = optional(list(string))<br/>    link_to_default_domain = bool<br/>    rule_set_keys          = optional(list(string))<br/>    cache = optional(object({<br/>      query_string_caching_behavior = string<br/>      query_strings                 = optional(list(string))<br/>      compression_enabled           = bool<br/>      content_types_to_compress     = optional(list(string))<br/>    }))<br/>  }))</pre> | n/a | yes |
| <a name="input_rule_sets"></a> [rule\_sets](#input\_rule\_sets) | A map of rule sets for this team's applications. | <pre>map(object({<br/>    name = string<br/>  }))</pre> | `{}` | no |
| <a name="input_rules"></a> [rules](#input\_rules) | A map of rules for this team's applications. | <pre>map(object({<br/>    name              = string<br/>    rule_set_key      = string<br/>    order             = number<br/>    behavior_on_match = string<br/>    actions = object({<br/>      url_redirect_action = optional(object({<br/>        redirect_type        = string<br/>        redirect_protocol    = string<br/>        destination_hostname = string<br/>        destination_path     = optional(string)<br/>        query_string         = optional(string)<br/>        destination_fragment = optional(string)<br/>      }))<br/>      url_rewrite_action = optional(object({<br/>        source_pattern          = string<br/>        destination             = string<br/>        preserve_unmatched_path = bool<br/>      }))<br/>      route_configuration_override_action = optional(object({<br/>        origin_group_key    = optional(string)<br/>        forwarding_protocol = optional(string)<br/>        cache_behavior      = optional(string)<br/>        cache_duration      = optional(string)<br/>        compression_enabled = optional(bool)<br/>      }))<br/>      request_header_actions = optional(list(object({<br/>        header_action = string<br/>        header_name   = string<br/>        value         = optional(string)<br/>      })))<br/>      response_header_actions = optional(list(object({<br/>        header_action = string<br/>        header_name   = string<br/>        value         = optional(string)<br/>      })))<br/>    })<br/>    conditions = optional(object({<br/>      remote_address_condition = optional(object({<br/>        operator         = string<br/>        negate_condition = bool<br/>        match_values     = list(string)<br/>      }))<br/>      request_method_condition = optional(object({<br/>        operator         = string<br/>        negate_condition = bool<br/>        match_values     = list(string)<br/>      }))<br/>      request_uri_condition = optional(object({<br/>        operator         = string<br/>        negate_condition = bool<br/>        match_values     = list(string)<br/>        transforms       = optional(list(string))<br/>      }))<br/>      url_path_condition = optional(object({<br/>        operator         = string<br/>        negate_condition = bool<br/>        match_values     = list(string)<br/>        transforms       = optional(list(string))<br/>      }))<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_shared_endpoint_name"></a> [shared\_endpoint\_name](#input\_shared\_endpoint\_name) | The name of the shared endpoint to use for routes. | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_custom_domain_ids"></a> [custom\_domain\_ids](#output\_custom\_domain\_ids) | A map of custom domain IDs. |
| <a name="output_custom_domain_validation_tokens"></a> [custom\_domain\_validation\_tokens](#output\_custom\_domain\_validation\_tokens) | A map of custom domain validation tokens for DNS verification. |
| <a name="output_origin_group_ids"></a> [origin\_group\_ids](#output\_origin\_group\_ids) | A map of origin group IDs. |
| <a name="output_origin_ids"></a> [origin\_ids](#output\_origin\_ids) | A map of origin IDs. |
| <a name="output_route_ids"></a> [route\_ids](#output\_route\_ids) | A map of route IDs. |
| <a name="output_rule_set_ids"></a> [rule\_set\_ids](#output\_rule\_set\_ids) | A map of rule set IDs. |
<!-- END_TF_DOCS -->
