variable "subscription_id" {
  description = "Azure subscription ID for compliance plan generation."
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group for the compliance plan."
  type        = string
}

variable "front_door_name" {
  description = "Name of the Front Door profile."
  type        = string
}

variable "sku_name" {
  description = "SKU name for the Front Door profile."
  type        = string
  default     = "Premium_AzureFrontDoor"
}

variable "waf_policy_name" {
  description = "Name of the WAF policy."
  type        = string
}

variable "waf_mode" {
  description = "Mode of the WAF policy."
  type        = string
  default     = "Prevention"
}

variable "shared_endpoints" {
  description = "Map of shared endpoints."
  type = map(object({
    name    = string
    enabled = bool
    tags    = optional(map(string), {})
  }))
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}
