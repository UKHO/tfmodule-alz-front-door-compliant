variable "subscription_id" {
  description = "Azure subscription ID for compliance plan generation."
  type        = string
}

variable "origin_groups" {
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
    cache = optional(object({
      query_string_caching_behavior = string
      query_strings                 = optional(list(string))
      compression_enabled           = bool
      content_types_to_compress     = optional(list(string))
    }))
  }))
}

variable "custom_domains" {
  type = map(object({
    name        = string
    dns_zone_id = string
    host_name   = string
    tls = object({
      certificate_type        = optional(string, "ManagedCertificate")
      minimum_tls_version     = optional(string, "TLS12")
      cdn_frontdoor_secret_id = optional(string)
    })
  }))
  default = {}
}
