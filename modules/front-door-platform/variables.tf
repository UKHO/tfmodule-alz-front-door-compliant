variable "front_door_name" {
  description = "The name of the Front Door profile."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the Front Door."
  type        = string
}

variable "sku_name" {
  description = "The SKU name of the Front Door profile. Possible values are Standard_AzureFrontDoor and Premium_AzureFrontDoor."
  type        = string
  default     = "Standard_AzureFrontDoor"
  validation {
    condition     = contains(["Standard_AzureFrontDoor", "Premium_AzureFrontDoor"], var.sku_name)
    error_message = "SKU name must be either Standard_AzureFrontDoor or Premium_AzureFrontDoor."
  }
}

variable "waf_policy_name" {
  description = "The name of the WAF policy."
  type        = string
}

variable "waf_mode" {
  description = "The mode of the WAF policy. Possible values are Detection and Prevention."
  type        = string
  default     = "Prevention"
  validation {
    condition     = contains(["Detection", "Prevention"], var.waf_mode)
    error_message = "WAF mode must be either Detection or Prevention."
  }
}

variable "waf_redirect_url" {
  description = "The redirect URL for the WAF policy."
  type        = string
  default     = null
}

variable "waf_custom_block_response_status_code" {
  description = "The custom block response status code for the WAF policy."
  type        = number
  default     = null
}

variable "waf_custom_block_response_body" {
  description = "The custom block response body for the WAF policy."
  type        = string
  default     = null
}

variable "waf_custom_rules" {
  description = "A list of custom rules for the WAF policy managed by platform team."
  type = list(object({
    name                           = string
    enabled                        = bool
    priority                       = number
    rate_limit_duration_in_minutes = optional(number)
    rate_limit_threshold           = optional(number)
    type                           = string
    action                         = string
    match_conditions = list(object({
      match_variable     = string
      operator           = string
      negation_condition = bool
      match_values       = list(string)
      transforms         = optional(list(string))
    }))
  }))
  default = []
}

variable "waf_managed_rules" {
  description = "A list of managed rules for the WAF policy."
  type = list(object({
    type    = string
    version = string
    action  = string
    exclusions = optional(list(object({
      match_variable = string
      operator       = string
      selector       = string
    })), [])
    overrides = optional(list(object({
      rule_group_name = string
      rules = list(object({
        rule_id = string
        enabled = bool
        action  = string
      }))
    })), [])
  }))
  default = [
    {
      type       = "Microsoft_DefaultRuleSet"
      version    = "2.1"
      action     = "Block"
      exclusions = []
      overrides  = []
    },
    {
      type       = "Microsoft_BotManagerRuleSet"
      version    = "1.0"
      action     = "Block"
      exclusions = []
      overrides  = []
    }
  ]
}

variable "shared_endpoints" {
  description = "A map of shared endpoints that delivery teams will use."
  type = map(object({
    name    = string
    enabled = bool
    tags    = optional(map(string), {})
  }))
}

variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
