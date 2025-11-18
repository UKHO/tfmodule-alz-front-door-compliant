# Azure Front Door Compliant Terraform Modules

[![Terraform](https://img.shields.io/badge/terraform-%3E%3D1.0-blue.svg)](https://www.terraform.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Validation](https://github.com/YOUR-USERNAME/tfmodule-alz-front-door-compliant/actions/workflows/terraform-validate.yml/badge.svg)](https://github.com/YOUR-USERNAME/tfmodule-alz-front-door-compliant/actions)

This repository contains two Terraform modules for managing Azure Front Door infrastructure with proper separation of concerns:

1. **Platform Module** (`modules/front-door-platform`) - Managed by Platform Team
2. **Delivery Module** (`modules/front-door-delivery`) - Used by Delivery Teams

> **⚠️ IMPORTANT**: This module has been restructured. If you were using the old single-module approach, see [CLEANUP.md](./CLEANUP.md) for migration instructions.

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Platform Team Manages                     │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ • Front Door Profile                                   │ │
│  │ • Base WAF Policy (Managed Rules)                      │ │
│  │ • Shared Endpoints                                     │ │
│  │ • Security Policies                                    │ │
│  └────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
                              │
                    References via Data Source
                              │
┌─────────────────────────────┼───────────────────────────────┐
│              Delivery Teams Manage (Separate State)          │
│  ┌──────────────────┐  ┌──────────────────┐  ┌────────────┐ │
│  │   Team A         │  │   Team B         │  │  Team C    │ │
│  │ • Origin Groups  │  │ • Origin Groups  │  │ • Routes   │ │
│  │ • Origins        │  │ • Origins        │  │ • Origins  │ │
│  │ • Routes         │  │ • Routes         │  │ • Domains  │ │
│  │ • Custom Domains │  │ • Rule Sets      │  └────────────┘ │
│  └──────────────────┘  └──────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## 📁 Repository Structure

```
tfmodule-alz-front-door-compliant/
├── README.md                    # This file
├── CLEANUP.md                   # Migration guide from old structure
├── COST_ESTIMATION.md          # Detailed cost breakdown
├── .gitignore                  # Git ignore patterns
│
├── modules/
│   ├── front-door-platform/    # Platform team module
│   │   ├── providers.tf
│   │   ├── frontdoor.tf       # Front Door profile
│   │   ├── waf.tf             # WAF policy & security
│   │   ├── endpoints.tf       # Shared endpoints
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   │
│   └── front-door-delivery/    # Delivery team module
│       ├── providers.tf
│       ├── data.tf            # References to platform resources
│       ├── origins.tf         # Origin groups & origins
│       ├── routes.tf          # Routes configuration
│       ├── custom_domains.tf # Custom domains
│       ├── rules.tf           # Rule sets & rules
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
│
└── examples/
    ├── platform-deployment/    # Platform team example ✅
    │   ├── main.tf
    │   └── README.md
    ├── team-deployment/        # Delivery team example ✅
    │   ├── main.tf
    │   └── README.md
    └── private-link/           # Private Link example ✅
        └── main.tf
```

## Quick Start

### Step 1: Platform Team Deploys Core Infrastructure

```hcl
module "front_door_platform" {
  source = "./modules/front-door-platform"

  front_door_name     = "company-frontdoor"
  resource_group_name = "rg-platform-networking"
  sku_name            = "Premium_AzureFrontDoor"
  waf_policy_name     = "wafplatform"
  
  shared_endpoints = {
    shared = {
      name    = "shared-endpoint"
      enabled = true
    }
  }

  tags = {
    ManagedBy = "Platform-Team"
    Environment = "Shared"
  }
}
```

### Step 2: Delivery Teams Deploy Their Routes

```hcl
module "team_a_routes" {
  source = "./modules/front-door-delivery"

  front_door_profile_name     = "company-frontdoor"
  front_door_resource_group   = "rg-platform-networking"
  shared_endpoint_name        = "shared-endpoint"

  origin_groups = {
    team_a_apps = {
      name = "team-a-origin-group"
      # ... configuration
    }
  }

  origins = {
    team_a_app = {
      name         = "team-a-app"
      host_name    = "team-a-app.azurewebsites.net"
      # ... configuration
    }
  }

  routes = {
    team_a_route = {
      name          = "team-a-route"
      patterns      = ["/team-a/*"]
      # ... configuration
    }
  }

  tags = {
    ManagedBy = "Team-A"
    Team      = "ApplicationA"
  }
}
```

## 🔄 Migration from Old Structure

If you were using this module before the restructure, **do not delete the old files immediately**. Follow the [CLEANUP.md](./CLEANUP.md) guide for safe migration steps.

**Key Changes:**
- ❌ Root-level `main.tf`, `variables.tf`, `outputs.tf` - **Deprecated**
- ✅ New modular structure in `modules/` directory
- ✅ Separate state files for platform and delivery teams
- ✅ Better separation of concerns and governance

## Benefits of This Architecture

### ✅ Security & Governance
- Platform controls core infrastructure (Profile, WAF, Security)
- Teams cannot modify platform settings
- WAF policy enforced centrally
- Clear ownership boundaries

### ✅ Independence & Safety
- Each team has separate Terraform state
- Teams deploy without coordinating
- No risk of overwriting other teams' configs
- Platform updates don't affect team routes

### ✅ Scalability
- New teams onboard independently
- No bottleneck on platform team
- Teams iterate at their own pace

### ✅ Cost Visibility
- Teams can see their own resource costs
- Platform costs centrally managed

## Module Documentation

- [Platform Module Documentation](./modules/front-door-platform/README.md)
- [Delivery Module Documentation](./modules/front-door-delivery/README.md)

# Azure Front Door Compliant Terraform Module

This Terraform module creates and manages an Azure Front Door (Standard or Premium) instance with Web Application Firewall (WAF) enabled, ensuring compliance with security policies.

## Features

- ✅ **WAF Policy Enabled by Default** - Complies with Azure policy requirements
- 🔒 **Security Best Practices** - Managed rules (DRS 2.1 + Bot Manager), custom rules support
- 🌐 **Custom Domain Support** - SSL/TLS certificate management with automatic validation
- ⚡ **Performance Optimization** - Caching, compression, CDN edge locations
- 🔄 **High Availability** - Health probes, load balancing, multiple origins
- 📊 **Monitoring Ready** - Outputs for integration with monitoring solutions
- 🎯 **Flexible Routing** - Rules engine, URL rewrites, redirects
- 🔐 **Private Link Support** - Secure backend connectivity to VNet resources (Premium SKU)

## Usage

### Basic Example

```hcl
module "front_door" {
  source = "c:/pgit/tfmodule-alz-front-door-compliant"

  front_door_name     = "my-frontdoor"
  resource_group_name = "my-rg"
  sku_name            = "Standard_AzureFrontDoor"
  waf_policy_name     = "my-waf-policy"
  waf_mode            = "Prevention"

  endpoints = {
    default = {
      name    = "my-endpoint"
      enabled = true
    }
  }

  origin_groups = {
    default = {
      name                     = "my-origin-group"
      session_affinity_enabled = false
      load_balancing = {
        sample_size                        = 4
        successful_samples_required        = 3
        additional_latency_in_milliseconds = 50
      }
      health_probe = {
        protocol            = "Https"
        interval_in_seconds = 100
        request_type        = "HEAD"
        path                = "/health"
      }
    }
  }

  origins = {
    default = {
      name                           = "my-origin"
      origin_group_key               = "default"
      enabled                        = true
      host_name                      = "example.com"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "example.com"
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = true
    }
  }

  routes = {
    default = {
      name                   = "my-route"
      endpoint_key           = "default"
      origin_group_key       = "default"
      origin_keys            = ["default"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      link_to_default_domain = true
      cache = {
        query_string_caching_behavior = "IgnoreQueryString"
        compression_enabled           = true
        content_types_to_compress     = ["text/html", "text/css", "application/javascript"]
      }
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

### Advanced Example with Custom Domain and Rules

```hcl
module "front_door_advanced" {
  source = "c:/pgit/tfmodule-alz-front-door-compliant"

  front_door_name     = "advanced-frontdoor"
  resource_group_name = "my-rg"
  sku_name            = "Premium_AzureFrontDoor"
  waf_policy_name     = "advanced-waf-policy"
  waf_mode            = "Prevention"

  # Custom WAF rules
  waf_custom_rules = [
    {
      name                           = "RateLimitRule"
      enabled                        = true
      priority                       = 1
      rate_limit_duration_in_minutes = 1
      rate_limit_threshold           = 100
      type                           = "RateLimitRule"
      action                         = "Block"
      match_conditions = [
        {
          match_variable     = "RemoteAddr"
          operator           = "IPMatch"
          negation_condition = false
          match_values       = ["0.0.0.0/0"]
          transforms         = null
        }
      ]
    }
  ]

  endpoints = {
    default = {
      name    = "advanced-endpoint"
      enabled = true
    }
  }

  origin_groups = {
    web = {
      name                     = "web-origin-group"
      session_affinity_enabled = true
      load_balancing = {
        sample_size                        = 4
        successful_samples_required        = 3
        additional_latency_in_milliseconds = 50
      }
      health_probe = {
        protocol            = "Https"
        interval_in_seconds = 30
        request_type        = "GET"
        path                = "/api/health"
      }
    }
  }

  origins = {
    primary = {
      name                           = "primary-origin"
      origin_group_key               = "web"
      enabled                        = true
      host_name                      = "primary.example.com"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "primary.example.com"
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = true
    }
    secondary = {
      name                           = "secondary-origin"
      origin_group_key               = "web"
      enabled                        = true
      host_name                      = "secondary.example.com"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "secondary.example.com"
      priority                       = 2
      weight                         = 500
      certificate_name_check_enabled = true
    }
  }

  custom_domains = {
    www = {
      name        = "www-example-com"
      dns_zone_id = azurerm_dns_zone.example.id
      host_name   = "www.example.com"
      tls = {
        certificate_type    = "ManagedCertificate"
        minimum_tls_version = "TLS12"
      }
    }
  }

  rule_sets = {
    security = {
      name = "security-rules"
    }
  }

  rules = {
    security_headers = {
      name              = "add-security-headers"
      rule_set_key      = "security"
      order             = 1
      behavior_on_match = "Continue"
      actions = {
        response_header_actions = [
          {
            header_action = "Append"
            header_name   = "X-Content-Type-Options"
            value         = "nosniff"
          },
          {
            header_action = "Append"
            header_name   = "X-Frame-Options"
            value         = "SAMEORIGIN"
          },
          {
            header_action = "Append"
            header_name   = "Strict-Transport-Security"
            value         = "max-age=31536000; includeSubDomains"
          }
        ]
      }
    }
  }

  routes = {
    default = {
      name                   = "default-route"
      endpoint_key           = "default"
      origin_group_key       = "web"
      origin_keys            = ["primary", "secondary"]
      enabled                = true
      forwarding_protocol    = "HttpsOnly"
      https_redirect_enabled = true
      patterns_to_match      = ["/*"]
      supported_protocols    = ["Http", "Https"]
      custom_domain_keys     = ["www"]
      link_to_default_domain = true
      rule_set_keys          = ["security"]
      cache = {
        query_string_caching_behavior = "UseQueryString"
        query_strings                 = ["utm_source", "utm_medium"]
        compression_enabled           = true
        content_types_to_compress = [
          "text/html",
          "text/css",
          "application/javascript",
          "application/json",
          "image/svg+xml"
        ]
      }
    }
  }

  tags = {
    Environment = "Production"
    Compliance  = "ALZ"
    ManagedBy   = "Terraform"
  }
}
```

### Private Link Example (Premium SKU)

Securely connect to private endpoints in Azure VNets without exposing origins to the public internet.

```hcl
module "front_door_private_link" {
  source = "c:/pgit/tfmodule-alz-front-door-compliant"

  front_door_name     = "fd-private-link"
  resource_group_name = azurerm_resource_group.example.name
  sku_name            = "Premium_AzureFrontDoor"  # Private Link requires Premium
  waf_policy_name     = "wafprivatelink"
  waf_mode            = "Prevention"

  endpoints = {
    default = {
      name    = "private-endpoint"
      enabled = true
    }
  }

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
        path                = "/health"
      }
    }
  }

  origins = {
    private_app_service = {
      name                           = "private-app-origin"
      origin_group_key               = "private_apps"
      enabled                        = true
      host_name                      = "myapp.azurewebsites.net"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "myapp.azurewebsites.net"
      priority                       = 1
      weight                         = 1000
      certificate_name_check_enabled = true
      
      # Private Link configuration
      private_link = {
        request_message        = "Request access from Front Door"
        target_type            = "sites"  # App Service
        location               = "eastus"
        private_link_target_id = azurerm_app_service.example.id
      }
    }
    
    private_storage = {
      name                           = "private-storage-origin"
      origin_group_key               = "private_apps"
      enabled                        = true
      host_name                      = "mystorageaccount.blob.core.windows.net"
      http_port                      = 80
      https_port                     = 443
      origin_host_header             = "mystorageaccount.blob.core.windows.net"
      priority                       = 2
      weight                         = 500
      certificate_name_check_enabled = true
      
      # Private Link to Storage Account
      private_link = {
        request_message        = "Request access from Front Door for storage"
        target_type            = "blob"  # Blob storage
        location               = "eastus"
        private_link_target_id = azurerm_storage_account.example.id
      }
    }
  }

  routes = {
    default = {
      name                   = "private-route"
      endpoint_key           = "default"
      origin_group_key       = "private_apps"
      origin_keys            = ["private_app_service", "private_storage"]
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
    Environment = "Production"
    Network     = "Private"
    ManagedBy   = "Terraform"
  }
}

# After applying, approve the Private Endpoint connection in the origin resource
resource "azurerm_app_service_private_endpoint_connection_approval" "example" {
  name                          = "frontdoor-private-link"
  private_endpoint_connection_id = module.front_door_private_link.origin_ids["private_app_service"]
}
```

## Input Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `front_door_name` | The name of the Front Door profile | `string` | n/a | yes |
| `resource_group_name` | The name of the resource group | `string` | n/a | yes |
| `sku_name` | SKU name (Standard_AzureFrontDoor or Premium_AzureFrontDoor) | `string` | `"Standard_AzureFrontDoor"` | no |
| `waf_policy_name` | The name of the WAF policy | `string` | n/a | yes |
| `waf_mode` | WAF mode (Detection or Prevention) | `string` | `"Prevention"` | no |
| `waf_custom_rules` | List of custom WAF rules | `list(object)` | `[]` | no |
| `waf_managed_rules` | List of managed WAF rules | `list(object)` | DRS 2.1 + Bot Manager | no |
| `endpoints` | Map of Front Door endpoints | `map(object)` | n/a | yes |
| `origin_groups` | Map of origin groups | `map(object)` | n/a | yes |
| `origins` | Map of origins | `map(object)` | n/a | yes |
| `routes` | Map of routes | `map(object)` | n/a | yes |
| `custom_domains` | Map of custom domains | `map(object)` | `{}` | no |
| `rule_sets` | Map of rule sets | `map(object)` | `{}` | no |
| `rules` | Map of rules | `map(object)` | `{}` | no |
| `tags` | Tags to assign to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| `front_door_id` | The ID of the Front Door profile |
| `front_door_name` | The name of the Front Door profile |
| `waf_policy_id` | The ID of the WAF policy |
| `endpoint_ids` | Map of endpoint IDs |
| `endpoint_host_names` | Map of endpoint host names |
| `origin_group_ids` | Map of origin group IDs |
| `origin_ids` | Map of origin IDs |
| `route_ids` | Map of route IDs |
| `custom_domain_ids` | Map of custom domain IDs |
| `custom_domain_validation_tokens` | Map of custom domain validation tokens |

## Security Best Practices

1. **WAF Always Enabled**: The module enforces WAF policy on all endpoints by default
2. **Managed Rules**: Default configuration includes Microsoft DRS 2.1 and Bot Manager
3. **TLS Configuration**: Minimum TLS 1.2, support for custom certificates
4. **HTTPS Redirect**: Enable `https_redirect_enabled` on routes
5. **Certificate Validation**: Enable `certificate_name_check_enabled` for origins
6. **Security Headers**: Use rules to add security headers (X-Frame-Options, HSTS, etc.)

## Performance Optimization

1. **Caching**: Configure caching behavior per route
2. **Compression**: Enable compression for appropriate content types
3. **Health Probes**: Configure health probes for origin availability
4. **Load Balancing**: Use multiple origins with priority and weight
5. **Session Affinity**: Enable for stateful applications

## Monitoring and Alerting

The module outputs can be used to configure monitoring:

```hcl
resource "azurerm_monitor_diagnostic_setting" "front_door" {
  name                       = "frontdoor-diagnostics"
  target_resource_id         = module.front_door.front_door_id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "FrontdoorAccessLog"
  }

  enabled_log {
    category = "FrontdoorWebApplicationFirewallLog"
  }

  metric {
    category = "AllMetrics"
  }
}
```

## VNet Integration with Private Link

Azure Front Door Premium supports **Private Link** for secure connectivity to origin resources in Azure VNets.

### Supported Origin Types

Private Link is supported for the following Azure resource types:

| Target Type | Azure Resource | Description |
|------------|----------------|-------------|
| `sites` | App Service / Function App | Web apps and APIs |
| `blob` | Storage Account (Blob) | Blob storage primary endpoint |
| `blob_secondary` | Storage Account (Blob) | Blob storage secondary endpoint |
| `web` | Storage Account (Static Website) | Static website hosting |
| `table` | Storage Account (Table) | Table storage |
| `queue` | Storage Account (Queue) | Queue storage |
| `file` | Storage Account (File) | File storage |
| `Microsoft.Sql/servers` | Azure SQL Database | SQL databases |
| `Microsoft.ContainerRegistry/registries` | Container Registry | Container images |

### Prerequisites

1. **Premium SKU Required**: Private Link only works with `Premium_AzureFrontDoor`
2. **Private Endpoint**: The origin resource must support Private Endpoints
3. **Approval Required**: After deployment, approve the Private Endpoint connection on the origin resource
4. **Network Configuration**: Ensure proper NSG and firewall rules allow Front Door connectivity

### Security Benefits

- ✅ **Zero Public Exposure**: Origins don't need public endpoints
- ✅ **VNet Isolation**: Backend resources stay within Azure VNet boundaries
- ✅ **Private Connectivity**: Traffic flows over Microsoft backbone network
- ✅ **Compliance**: Meets requirements for private network architectures
- ✅ **DDoS Protection**: Origins protected from direct internet attacks

### Configuration Steps

1. **Deploy Front Door with Private Link configuration**
2. **Approve Private Endpoint connection** on the origin resource (Azure Portal or CLI)
3. **Verify connectivity** through health probes
4. **Configure DNS** (if using custom domains)

### Example: App Service with Private Link

```hcl
# App Service (origin)
resource "azurerm_app_service" "example" {
  name                = "myapp"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.example.name
  app_service_plan_id = azurerm_app_service_plan.example.id

  # Disable public access
  public_network_access_enabled = false
}

# Front Door with Private Link
module "front_door" {
  source = "c:/pgit/tfmodule-alz-front-door-compliant"
  
  # ... basic configuration ...
  
  sku_name = "Premium_AzureFrontDoor"  # Required for Private Link
  
  origins = {
    app = {
      # ... other settings ...
      private_link = {
        request_message        = "Front Door Private Link"
        target_type            = "sites"
        location               = azurerm_app_service.example.location
        private_link_target_id = azurerm_app_service.example.id
      }
    }
  }
}
```

### Monitoring Private Link Connections

Monitor Private Endpoint connections using Azure Monitor:

```hcl
resource "azurerm_monitor_diagnostic_setting" "origin" {
  name                       = "origin-private-link"
  target_resource_id         = azurerm_app_service.example.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.example.id

  enabled_log {
    category = "AppServicePrivateLinkLog"
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0 |
| azurerm | >= 3.0 |

## Pricing

Azure Front Door pricing is based on multiple factors and is charged **hourly** (prorated to the second).

### Base Pricing (as of 2024)

| Component | Standard SKU | Premium SKU |
|-----------|-------------|-------------|
| **Base Fee** | ~$35/month (~$0.048/hour) | ~$330/month (~$0.45/hour) |
| **Data Transfer Out (first 10 TB)** | $0.085/GB | $0.085/GB |
| **HTTP/HTTPS Requests** | $0.0075 per 10,000 requests | $0.0075 per 10,000 requests |
| **Rule Engine** | Included | Included |
| **Custom Domains** | Included | Included |
| **Managed Certificates** | Free | Free |

### Premium-Only Features

Premium SKU is required for:
- ✅ Private Link connectivity (~$0.01/hour per private endpoint)
- ✅ Advanced WAF features
- ✅ Bot protection rules
- ✅ Enhanced metrics and logs

### WAF Pricing (Included in Base Fee)

- **WAF Policy**: Included in base price
- **Custom Rules**: First 5 free, then $1/rule/month
- **Managed Rules (DRS + Bot Manager)**: Included
- **WAF Requests**: $0.50 per 1 million requests

### Data Transfer Pricing

Data transfer out varies by volume:
- **0-10 TB**: $0.085/GB
- **10-50 TB**: $0.080/GB
- **50-150 TB**: $0.060/GB
- **150-500 TB**: $0.040/GB
- **500+ TB**: $0.030/GB

### Cost Examples

#### Small Website (Standard SKU)
- Base fee: $35/month
- 100 GB data transfer: $8.50
- 1 million requests: $0.75
- **Total: ~$44/month**

#### Medium Application (Standard SKU)
- Base fee: $35/month
- 1 TB data transfer: $85
- 10 million requests: $7.50
- 2 custom WAF rules: $2
- **Total: ~$130/month**

#### Large Application (Premium SKU with Private Link)
- Base fee: $330/month
- 10 TB data transfer: $850
- 100 million requests: $75
- 5 custom WAF rules: Free (first 5)
- 3 private endpoints: $22 (~$0.01/hour × 3 × 730 hours)
- WAF requests (50M): $25
- **Total: ~$1,302/month**

### Cost Optimization Tips

1. **Use Caching**: Reduce origin requests and data transfer
2. **Enable Compression**: Reduce data transfer costs by 60-80%
3. **Choose Right SKU**: Use Standard unless you need Private Link
4. **Monitor Custom Rules**: Each rule after 5 costs $1/month
5. **Optimize Health Probes**: Reduce probe frequency if origins are stable
6. **Use Query String Caching**: Avoid cache misses from unnecessary query params

### Billing Model

- **Prorated Hourly**: Charged to the second, billed hourly
- **Pay-as-you-go**: No upfront commitment required
- **Monthly Billing**: Charges appear on your Azure invoice monthly
- **Per Resource**: Each Front Door profile is billed separately

### Cost Monitoring

Monitor costs using Azure Cost Management:

```hcl
# Example: Set up budget alert for Front Door
resource "azurerm_consumption_budget_resource_group" "front_door" {
  name              = "front-door-budget"
  resource_group_id = azurerm_resource_group.example.id

  amount     = 500
  time_grain = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  filter {
    dimension {
      name = "ResourceType"
      values = [
        "Microsoft.Cdn/profiles"
      ]
    }
  }

  notification {
    enabled        = true
    threshold      = 80
    operator       = "GreaterThan"
    contact_emails = ["team@example.com"]
  }

  notification {
    enabled        = true
    threshold      = 100
    operator       = "GreaterThan"
    contact_emails = ["alerts@example.com"]
  }
}
```

### Additional Costs to Consider

- **Azure DNS** (if using custom domains): ~$0.50/zone/month + $0.40 per million queries
- **Log Analytics** (if storing logs): $2.30/GB ingested
- **Application Insights** (if monitoring): Variable based on data volume
- **Azure Monitor Alerts**: $0.10 per alert rule per month

### Pricing Calculator

Use the official [Azure Pricing Calculator](https://azure.microsoft.com/en-us/pricing/calculator/) for accurate estimates based on your specific usage patterns.

**Note**: Prices are approximate and vary by region. Check the [official Azure Front Door pricing page](https://azure.microsoft.com/en-us/pricing/details/frontdoor/) for current rates.

## License

This module is provided as-is for organizational use.

## Contributing

Please follow organizational standards for contributions and ensure all changes are tested before deployment.

## 🔄 CI/CD Pipeline

### GitHub Actions (Validation & Quality)
Automated checks on every push and pull request:
- ✅ Terraform formatting validation
- ✅ Terraform syntax validation
- ✅ Documentation completeness check
- ✅ Security scanning (Trivy)
- ✅ Module structure validation

**Note:** GitHub Actions do NOT deploy to Azure. They only validate code quality.

### Azure Pipelines (Deployment)
Actual infrastructure deployments are managed through **Azure Pipelines**:
- Platform team deployments to Azure
- Integration with Azure DevOps
- Secure credential management
- Environment-specific deployments
- Approval gates for production

See your organization's Azure DevOps documentation for deployment procedures.
