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
| [azurerm_cdn_frontdoor_endpoint.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_endpoint) | resource |
| [azurerm_cdn_frontdoor_firewall_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_firewall_policy) | resource |
| [azurerm_cdn_frontdoor_profile.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_profile) | resource |
| [azurerm_cdn_frontdoor_secret.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_secret) | resource |
| [azurerm_cdn_frontdoor_security_policy.this](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cdn_frontdoor_security_policy) | resource |
| [azurerm_role_assignment.frontdoor_kv_secrets_user](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource |
| [azurerm_key_vault.frontdoor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/key_vault) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_front_door_name"></a> [front\_door\_name](#input\_front\_door\_name) | The name of the Front Door profile. | `string` | n/a | yes |
| <a name="input_key_vault_name"></a> [key\_vault\_name](#input\_key\_vault\_name) | The name of the Key Vault containing certificates for Front Door secrets. Used to grant the Front Door managed identity the Key Vault Secrets User role. | `string` | `null` | no |
| <a name="input_key_vault_resource_group_name"></a> [key\_vault\_resource\_group\_name](#input\_key\_vault\_resource\_group\_name) | The resource group containing the Key Vault. Defaults to the shared connectivity resource group. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | The name of the resource group in which to create the Front Door. | `string` | n/a | yes |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | A map of Key Vault certificates to import as Front Door secrets. Referenced by custom domains using certificate\_type = "CustomerCertificate". | <pre>map(object({<br/>    name                     = string<br/>    key_vault_certificate_id = string<br/>  }))</pre> | `{}` | no |
| <a name="input_shared_endpoints"></a> [shared\_endpoints](#input\_shared\_endpoints) | A map of shared endpoints that delivery teams will use. | <pre>map(object({<br/>    name    = string<br/>    enabled = bool<br/>    tags    = optional(map(string), {})<br/>  }))</pre> | n/a | yes |
| <a name="input_sku_name"></a> [sku\_name](#input\_sku\_name) | The SKU name of the Front Door profile. Possible values are Standard\_AzureFrontDoor and Premium\_AzureFrontDoor. | `string` | `"Standard_AzureFrontDoor"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | A mapping of tags to assign to the resources. | `map(string)` | `{}` | no |
| <a name="input_waf_custom_block_response_body"></a> [waf\_custom\_block\_response\_body](#input\_waf\_custom\_block\_response\_body) | The custom block response body for the WAF policy. | `string` | `null` | no |
| <a name="input_waf_custom_block_response_status_code"></a> [waf\_custom\_block\_response\_status\_code](#input\_waf\_custom\_block\_response\_status\_code) | The custom block response status code for the WAF policy. | `number` | `null` | no |
| <a name="input_waf_custom_rules"></a> [waf\_custom\_rules](#input\_waf\_custom\_rules) | A list of custom rules for the WAF policy managed by platform team. | <pre>list(object({<br/>    name                           = string<br/>    enabled                        = bool<br/>    priority                       = number<br/>    rate_limit_duration_in_minutes = optional(number)<br/>    rate_limit_threshold           = optional(number)<br/>    type                           = string<br/>    action                         = string<br/>    match_conditions = list(object({<br/>      match_variable     = string<br/>      operator           = string<br/>      negation_condition = bool<br/>      match_values       = list(string)<br/>      transforms         = optional(list(string))<br/>    }))<br/>  }))</pre> | `[]` | no |
| <a name="input_waf_managed_rules"></a> [waf\_managed\_rules](#input\_waf\_managed\_rules) | A list of managed rules for the WAF policy. | <pre>list(object({<br/>    type    = string<br/>    version = string<br/>    action  = string<br/>    exclusions = optional(list(object({<br/>      match_variable = string<br/>      operator       = string<br/>      selector       = string<br/>    })), [])<br/>    overrides = optional(list(object({<br/>      rule_group_name = string<br/>      rules = list(object({<br/>        rule_id = string<br/>        enabled = bool<br/>        action  = string<br/>      }))<br/>    })), [])<br/>  }))</pre> | <pre>[<br/>  {<br/>    "action": "Block",<br/>    "exclusions": [],<br/>    "overrides": [],<br/>    "type": "Microsoft_DefaultRuleSet",<br/>    "version": "2.1"<br/>  },<br/>  {<br/>    "action": "Block",<br/>    "exclusions": [],<br/>    "overrides": [],<br/>    "type": "Microsoft_BotManagerRuleSet",<br/>    "version": "1.0"<br/>  }<br/>]</pre> | no |
| <a name="input_waf_mode"></a> [waf\_mode](#input\_waf\_mode) | The mode of the WAF policy. Possible values are Detection and Prevention. | `string` | `"Prevention"` | no |
| <a name="input_waf_policy_name"></a> [waf\_policy\_name](#input\_waf\_policy\_name) | The name of the WAF policy. | `string` | n/a | yes |
| <a name="input_waf_redirect_url"></a> [waf\_redirect\_url](#input\_waf\_redirect\_url) | The redirect URL for the WAF policy. | `string` | `null` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_endpoint_host_names"></a> [endpoint\_host\_names](#output\_endpoint\_host\_names) | A map of endpoint host names. |
| <a name="output_endpoint_ids"></a> [endpoint\_ids](#output\_endpoint\_ids) | A map of endpoint IDs. |
| <a name="output_front_door_id"></a> [front\_door\_id](#output\_front\_door\_id) | The ID of the Front Door profile. |
| <a name="output_front_door_name"></a> [front\_door\_name](#output\_front\_door\_name) | The name of the Front Door profile. |
| <a name="output_resource_group_name"></a> [resource\_group\_name](#output\_resource\_group\_name) | The resource group name containing the Front Door. |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | A map of Front Door secret IDs keyed by the secrets map key. Pass these to the delivery module's custom\_domains[*].tls.cdn\_frontdoor\_secret\_id when using CustomerCertificate TLS. |
| <a name="output_sku_name"></a> [sku\_name](#output\_sku\_name) | The SKU name of the Front Door profile. |
| <a name="output_waf_policy_id"></a> [waf\_policy\_id](#output\_waf\_policy\_id) | The ID of the WAF policy. |
<!-- END_TF_DOCS -->
