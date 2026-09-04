variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "resource_group_name_prefix" {
  description = "Prefix for the fixture resource group name. Gets '-platform-<random>' suffix appended."
  type        = string
  default     = "rg-frontdoor-overlaptest"
}

variable "location" {
  description = "Azure region for fixture resources."
  type        = string
  default     = "uksouth"
}

variable "front_door_profile_name" {
  description = "Base name for the shared Front Door profile both delivery instances will reference. Gets a random suffix appended."
  type        = string
  default     = "fd-overlaptest"
}

variable "shared_endpoint_name" {
  description = "Base name for the shared endpoint both delivery instances will reference. Gets a random suffix appended (endpoint names must be globally unique across Azure)."
  type        = string
  default     = "fd-overlaptest-ep"
}

variable "dns_zone_name" {
  description = "Name of the throwaway DNS zone used for custom-domain overlap testing."
  type        = string
  default     = "overlaptest.internal"
}

variable "environment_tag" {
  description = "Value for mandatory 'environment' tag."
  type        = string
  default     = "test"
}

variable "managed_by_tag" {
  description = "Value for mandatory 'managed-by' tag."
  type        = string
  default     = "platform"
}
