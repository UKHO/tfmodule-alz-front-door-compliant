# Azure Front Door Platform Module

**Owner**: Platform Team  
**Purpose**: Creates and manages the core Azure Front Door infrastructure

## Responsibilities

This module manages:
- ✅ Front Door Profile
- ✅ Base WAF Policy with managed rules
- ✅ Shared endpoints
- ✅ Security policies
- ✅ Platform-level configuration

## What Teams CANNOT Change

- Front Door SKU
- Base WAF managed rules
- Security policy enforcement
- Shared endpoint names

## Usage

```hcl
module "front_door_platform" {
  source = "./modules/front-door-platform"

  front_door_name     = "company-frontdoor"
  resource_group_name = "rg-platform-networking"
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
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| `front_door_name` | Front Door profile name | `string` | n/a | yes |
| `resource_group_name` | Resource group name | `string` | n/a | yes |
| `sku_name` | SKU (Standard or Premium) | `string` | `"Standard_AzureFrontDoor"` | no |
| `waf_policy_name` | WAF policy name | `string` | n/a | yes |
| `shared_endpoints` | Shared endpoints for teams | `map(object)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| `front_door_id` | Front Door profile ID |
| `front_door_name` | Front Door profile name |
| `waf_policy_id` | WAF policy ID |
| `endpoint_ids` | Map of endpoint IDs |

## Deployment

Platform team deploys this module first:

```bash
cd examples/platform-deployment
terraform init
terraform plan
terraform apply
```

## Updates & Maintenance

### Safe Updates
- ✅ Adding new shared endpoints
- ✅ Updating WAF managed rule versions
- ✅ Adding platform-level custom rules
- ✅ Updating tags

### Risky Updates
- ⚠️ Changing SKU (requires planning with teams)
- ⚠️ Changing WAF mode (coordinate with teams)
- ⚠️ Renaming endpoints (breaks team references)

## Support

For questions contact: platform-team@company.com
