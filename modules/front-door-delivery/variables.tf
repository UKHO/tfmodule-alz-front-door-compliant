variable "front_door_profile_name" {
  description = "The name of the existing Front Door profile created by platform team."
  type        = string
}

variable "front_door_resource_group" {
  description = "The resource group containing the Front Door profile."
  type        = string
}

variable "shared_endpoint_name" {
  description = "The name of the shared endpoint to use for routes."
  type        = string
}

variable "origin_groups" {
  description = "A map of origin groups for this team's applications."
  type = map(object({
    name                     = string
    session_affinity_enabled = bool
    load_balancing = object({
      sample_size                        = number
      successful_samples_required        = number
      additional_latency_in_milliseconds = number
    })
    health_probe = optional(object({
      protocol            = string
      interval_in_seconds = number
      request_type        = string
      path                = string
    }))
  }))
}

variable "origins" {
  description = <<-EOT
    A map of origins for this team's applications.
    
    Private Link Integration (Premium SKU only):
    - Set private_link block to connect to private endpoints in VNets
    - Supported target_types: blob, blob_secondary, web, sites, table, queue, file
    - Requires Premium_AzureFrontDoor SKU (set by platform team)
    - Origin must have a private endpoint configured
  EOT
  type = map(object({
    name                           = string
    origin_group_key               = string
    enabled                        = bool
    host_name                      = string
    http_port                      = number
    https_port                     = number
    origin_host_header             = string
    priority                       = number
    weight                         = number
    certificate_name_check_enabled = bool
    private_link = optional(object({
      request_message        = string
      target_type            = string
      location               = string
      private_link_target_id = string
    }))
  }))
}

variable "routes" {
  description = "A map of routes for this team's applications."
  type = map(object({
    name                   = string
    origin_group_key       = string
    origin_keys            = list(string)
    enabled                = bool
    forwarding_protocol    = string
    https_redirect_enabled = bool
    patterns_to_match      = list(string)
    supported_protocols    = list(string)
    custom_domain_keys     = optional(list(string))
    link_to_default_domain = bool
    rule_set_keys          = optional(list(string))
    cache = optional(object({
      query_string_caching_behavior = string
      query_strings                 = optional(list(string))
      compression_enabled           = bool
      content_types_to_compress     = optional(list(string))
    }))
  }))
}

variable "custom_domains" {
  description = "A map of custom domains for this team's applications."
  type = map(object({
    name        = string
    dns_zone_id = string
    host_name   = string
    tls = object({
      certificate_type        = string
      minimum_tls_version     = string
      cdn_frontdoor_secret_id = optional(string)
    })
  }))
  default = {}
}

variable "rule_sets" {
  description = "A map of rule sets for this team's applications."
  type = map(object({
    name = string
  }))
  default = {}
}

variable "rules" {
  description = "A map of rules for this team's applications."
  type = map(object({
    name              = string
    rule_set_key      = string
    order             = number
    behavior_on_match = string
    actions = object({
      url_redirect_action = optional(object({
        redirect_type        = string
        redirect_protocol    = string
        destination_hostname = string
        destination_path     = optional(string)
        query_string         = optional(string)
        destination_fragment = optional(string)
      }))
      url_rewrite_action = optional(object({
        source_pattern          = string
        destination             = string
        preserve_unmatched_path = bool
      }))
      route_configuration_override_action = optional(object({
        origin_group_key    = optional(string)
        forwarding_protocol = optional(string)
        cache_behavior      = optional(string)
        cache_duration      = optional(string)
        compression_enabled = optional(bool)
      }))
      request_header_actions = optional(list(object({
        header_action = string
        header_name   = string
        value         = optional(string)
      })))
      response_header_actions = optional(list(object({
        header_action = string
        header_name   = string
        value         = optional(string)
      })))
    })
    conditions = optional(object({
      remote_address_condition = optional(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      request_method_condition = optional(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
      }))
      request_uri_condition = optional(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = optional(list(string))
      }))
      url_path_condition = optional(object({
        operator         = string
        negate_condition = bool
        match_values     = list(string)
        transforms       = optional(list(string))
      }))
    }))
  }))
  default = {}
}

variable "tags" {
  description = "A mapping of tags to assign to the resources."
  type        = map(string)
  default     = {}
}
