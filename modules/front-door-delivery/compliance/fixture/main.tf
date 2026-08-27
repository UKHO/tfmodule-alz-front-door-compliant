# Compliance fixture for the front-door-delivery module.
#
# The front-door-delivery module uses data sources to look up the shared Front Door
# profile and endpoint from Azure at plan time. These lookups require real deployed
# infrastructure, which is not available in a compliance-only context.
#
# This fixture replicates the resources that the module creates, replacing the two
# data source ID references with static stub values. This allows terraform plan to
# succeed without Azure connectivity, producing a plan JSON that terraform-compliance
# can inspect for policy assertions.
#
# The resource configurations are identical to those in the module — only the two
# data-source-derived IDs (cdn_frontdoor_profile_id and cdn_frontdoor_endpoint_id)
# are replaced with stub resource IDs of the correct format.

locals {
  stub_profile_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-compliance-test/providers/Microsoft.Cdn/profiles/fd-compliance-test"
  stub_endpoint_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-compliance-test/providers/Microsoft.Cdn/profiles/fd-compliance-test/afdEndpoints/ep-compliance-test"
}

resource "azurerm_cdn_frontdoor_origin_group" "this" {
  for_each = var.origin_groups

  name                     = each.value.name
  cdn_frontdoor_profile_id = local.stub_profile_id
  session_affinity_enabled = each.value.session_affinity_enabled

  load_balancing {
    sample_size                        = each.value.load_balancing.sample_size
    successful_samples_required        = each.value.load_balancing.successful_samples_required
    additional_latency_in_milliseconds = each.value.load_balancing.additional_latency_in_milliseconds
  }

  dynamic "health_probe" {
    for_each = each.value.health_probe != null ? [each.value.health_probe] : []
    content {
      protocol            = health_probe.value.protocol
      interval_in_seconds = health_probe.value.interval_in_seconds
      request_type        = health_probe.value.request_type
      path                = health_probe.value.path
    }
  }
}

resource "azurerm_cdn_frontdoor_origin" "this" {
  for_each = var.origins

  name                           = each.value.name
  cdn_frontdoor_origin_group_id  = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  enabled                        = each.value.enabled
  host_name                      = each.value.host_name
  http_port                      = each.value.http_port
  https_port                     = each.value.https_port
  origin_host_header             = each.value.origin_host_header
  priority                       = each.value.priority
  weight                         = each.value.weight
  certificate_name_check_enabled = each.value.certificate_name_check_enabled

  dynamic "private_link" {
    for_each = each.value.private_link != null ? [each.value.private_link] : []
    content {
      request_message        = private_link.value.request_message
      target_type            = private_link.value.target_type
      location               = private_link.value.location
      private_link_target_id = private_link.value.private_link_target_id
    }
  }
}

resource "azurerm_cdn_frontdoor_custom_domain" "this" {
  for_each = var.custom_domains

  name                     = each.value.name
  cdn_frontdoor_profile_id = local.stub_profile_id
  dns_zone_id              = each.value.dns_zone_id
  host_name                = each.value.host_name

  tls {
    certificate_type        = each.value.tls.certificate_type
    minimum_tls_version     = each.value.tls.minimum_tls_version
    cdn_frontdoor_secret_id = each.value.tls.certificate_type == "CustomerCertificate" ? each.value.tls.cdn_frontdoor_secret_id : null
  }
}

resource "azurerm_cdn_frontdoor_route" "this" {
  for_each = var.routes

  name                            = each.value.name
  cdn_frontdoor_endpoint_id       = local.stub_endpoint_id
  cdn_frontdoor_origin_group_id   = azurerm_cdn_frontdoor_origin_group.this[each.value.origin_group_key].id
  cdn_frontdoor_origin_ids        = [for origin_key in each.value.origin_keys : azurerm_cdn_frontdoor_origin.this[origin_key].id]
  enabled                         = each.value.enabled
  forwarding_protocol             = each.value.forwarding_protocol
  https_redirect_enabled          = each.value.https_redirect_enabled
  patterns_to_match               = each.value.patterns_to_match
  supported_protocols             = each.value.supported_protocols
  cdn_frontdoor_custom_domain_ids = each.value.custom_domain_keys != null ? [for domain_key in each.value.custom_domain_keys : azurerm_cdn_frontdoor_custom_domain.this[domain_key].id] : []
  link_to_default_domain          = each.value.link_to_default_domain

  dynamic "cache" {
    for_each = each.value.cache != null ? [each.value.cache] : []
    content {
      query_string_caching_behavior = cache.value.query_string_caching_behavior
      query_strings                 = cache.value.query_strings
      compression_enabled           = cache.value.compression_enabled
      content_types_to_compress     = cache.value.content_types_to_compress
    }
  }
}
